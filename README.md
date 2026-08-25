# Kaizo

『スーパーマリオワールド　カイゾウ』

A strict, punishing [RuboCop](https://rubocop.org) extension aimed at
AI-agent-authored Ruby — holding generated code to a demanding design bar.

_Kaizo_ (改造) — "remodeling", "modification": the ruleset keeps applying
pressure until the code is remade into something better. A long argument list
is the canonical target — loose primitives that want to be modeled as an
object:

```ruby
# bad — four loose primitives thread through the signature
def calculate_volume(width, length, height, shape_type)
end

# good — the abstraction has a name
def calculate_volume(shape)
end
```

```console
$ rubocop --only Kaizo volume.rb
volume.rb:1:5: C: Kaizo/PositionalArguments: Method has too many positional arguments. [4/1]
def calculate_volume(width, length, height, shape_type)
    ^^^^^^^^^^^^^^^^
volume.rb:1:5: C: Kaizo/TotalArguments: Method has too many arguments. [4/2]
def calculate_volume(width, length, height, shape_type)
    ^^^^^^^^^^^^^^^^

1 file inspected, 2 offenses detected
```

Every example in this README is executed against the shipped configuration by
the test suite: `# bad` code really is flagged by the named cop, `# good` code
really passes every cop, every YAML snippet is valid config, and the terminal
output above is re-derived from the cops themselves. Where a section covers
several cops, each bad example names the one that fires.

## Cops

| Cop | Flags |
|-----|-------|
| [`Kaizo/PositionalArguments`](#argument-counts) | more than `Max` positional parameters |
| [`Kaizo/KeywordArguments`](#argument-counts) | more than `Max` keyword parameters |
| [`Kaizo/TotalArguments`](#argument-counts) | more than `Max` parameters in total |
| [`Kaizo/AgentNounClassName`](#class-naming) | classes named for what they do, not what they model |
| [`Kaizo/NestedMethodCalls`](#nested-method-calls) | calls buried in other calls' arguments |
| [`Kaizo/SpecComment`](#comments-in-specs) | comments in spec files |
| [`Kaizo/SpecDescriptionProse`](#spec-description-prose) | descriptions that are lists, conditions, or code |
| [`Kaizo/SpecSubject`](#spec-subject) | the unit under test hidden in a `let` |
| [`Kaizo/FileUtilsInclusion`](#including-fileutils) | repeated `FileUtils.` qualification |
| [`Kaizo/PreferPathname`](#prefer-pathname) | `File` class methods `Pathname` already provides |
| [`Kaizo/TempfileCreate`](#temp-files) | temp-file APIs with nondeterministic cleanup |
| [`Kaizo/ExplicitBegin`](#explicit-begin) | `rescue`/`ensure` attached straight to `def` |
| [`Kaizo/NextInNonVoidEnumerable`](#next-in-value-returning-blocks) | `next` as a value in `map`/`select`/`reduce` |
| [`Kaizo/PluralCollectionName`](#plural-names-for-collections) | arrays returned under singular names |

**Every cop ships enabled.** `plugins: [kaizo]` turns all fourteen on at
their strict defaults — there is nothing to opt into and no pending status.
Outside its own department kaizo touches two core cops: it disables
`Style/RedundantBegin` ([Explicit begin](#explicit-begin)) and sets
`Style/HashSyntax` to enforce Ruby 3.1's hash-value shorthand —
`Session.new(table:)` over `Session.new(table: table)`.

The three argument cops are independent dimensions — enable the smallest set
that expresses your rule; a method breaking several bounds is reported once
per cop. None of the cops autocorrect — every fix is a design decision — with
one exception: `Kaizo/ExplicitBegin`, whose `begin`/`end` wrap is mechanical
(`rubocop -a`).

## Installation

```ruby
gem 'kaizo', require: false
```

```yaml
plugins:
  - kaizo
```

Requires RuboCop 1.72.2+ for the `lint_roller` plugin API.

## Argument counts

The defaults are deliberately strict — at most one positional and one keyword
argument. Loosen them, or set a `Max` to `0` to forbid that kind entirely:

```yaml
Kaizo/PositionalArguments:
  Max: 1        # default; 0 forces every argument to be a keyword
Kaizo/KeywordArguments:
  Max: 1        # default
Kaizo/TotalArguments:
  Max: 2        # default (one positional + one keyword)
```

All three check `def`, `def self.`, `define_method`, and
`define_singleton_method`. Required and optional parameters count alike:

```ruby
# bad — Kaizo/TotalArguments: two positional plus two keyword exceed Max 2
def route(verb, path, to:, name: nil)
end

# bad — Kaizo/KeywordArguments: three keyword parameters exceed Max 1
def connect(host:, port:, scheme:)
end

# good — Kaizo/KeywordArguments counts none of these: collectors are single
# tokens, not lists of primitives
def log(*messages, **context, &formatter)
end
```

The keyword-counting cops skip `spec/` and `test/` trees entirely: wide
keyword interfaces are the testing idiom — FactoryBot's `create`/`build`,
custom builder helpers — and keywords communicate fine at any width there.
Positional pressure is universal, because positional arguments communicate
nothing unless they are solo:

```ruby
# good — spec/support/builders.rb: a wide keyword builder is normal test
# infrastructure, so Kaizo/KeywordArguments and Kaizo/TotalArguments skip it
def create_order(customer:, items:, coupon: nil, shipping: :standard)
  Order.create(customer:, items:, coupon:, shipping:)
end

# bad — Kaizo/PositionalArguments: spec/support/builders.rb is not exempt
# from positional pressure; three anonymous values say nothing
def build_order(customer, items, coupon)
  Order.create(customer:, items:, coupon:)
end
```

Police tests like everything else by clearing the exclusion:

```yaml
Kaizo/KeywordArguments:
  Exclude: []        # count keywords in tests too
Kaizo/TotalArguments:
  Exclude: []
```

Two shapes are structurally exempt:

```ruby
# good — a Struct/Data initialize mirrors the value object's attributes,
# which is exactly the modeling these cops push toward
Data.define(:width, :height, :depth) do
  def initialize(width:, height:, depth:)
    super
  end
end

# good — operator arity is fixed by Ruby's syntax; there is no object to
# extract (`[]`, `<=>`, `+`, `<<`, and the rest of the family likewise)
def []=(row, column, value)
  @cells[row][column] = value
end
```

Beyond the structural exemptions, exempt methods by name or pattern:

```yaml
Kaizo/KeywordArguments:
  Max: 1
  AllowedMethods:
    - initialize     # constructors may gather collaborators
Kaizo/PositionalArguments:
  AllowedPatterns:
    - '\Abuild_'     # or exempt a whole naming family
```

### `define_method` edge cases

```ruby
# good — only the block form of define_method is inspected; a callable body
# may be any object that responds to call, and is not statically countable
define_method(:resize, ->(width, height) { @size = [width, height] })

# good — numbered and `it` parameters are not a declared signature, so they
# count as zero; spell parameters out if you want them counted
define_method(:squared) { _1 * _1 }

# bad — Kaizo/TotalArguments: a name computed at runtime is still checked;
# the declared parameters matter, not how the name is spelled
define_method(:"handle_#{event}") { |source, payload, context| dispatch(source) }
```

## Relationship to `Metrics/ParameterLists`

Core's `Metrics/ParameterLists` caps the whole parameter list; kaizo bounds
positional and keyword arguments separately and is framed around domain
modeling. They can coexist. Full rationale with reproducible evidence:
[docs/why-not-metrics-parameterlists.md](docs/why-not-metrics-parameterlists.md).

## Class naming

`Kaizo/AgentNounClassName` flags classes named as agent nouns — "doers" —
rather than the domain concepts they model: names ending in `er`/`or`, or in
a configured forbidden suffix like `Service`.

```ruby
# bad — an -er name describes behavior, not a concept
class PaymentProcessor
end

# bad — Struct/Data/Class constant assignments are checked too
RequestHandler = Data.define(:request)

# good
class Payment
end

# good — ends in an allowed suffix
class UsersController
end
```

Two configurable suffix lists drive it, matched against the last segment of a
namespaced name. `AllowedSuffixes` exempts legitimate `-er`/`-or` words and
ships with a broad default (`Adapter`, `Controller`, `Error`, `User`, ...);
`ForbiddenSuffixes` always wins, which is how a default exemption is dropped:

```yaml
Kaizo/AgentNounClassName:
  inherit_mode:
    merge:
      - AllowedSuffixes
      - ForbiddenSuffixes
  AllowedSuffixes:
    - Voucher     # PaymentVoucher now passes
  ForbiddenSuffixes:
    - Server      # ApiServer now flagged, despite the default allowance
```

## Nested method calls

`Kaizo/NestedMethodCalls` flags calls nested too deeply in **argument**
positions — intermediate results want names.

```ruby
# bad
wrap(parse(read(io)))

# good — the name turns the step into its own documentation
parsed_config = parse(read(io))
wrap(parsed_config)

# good — a single nested call is fine at the default Max
puts compute(value)
```

A local called `result` or `tmp` satisfies the cop but not the reader — the
point is the name. Only argument nesting counts: receiver chains
(`user.account.owner`) are a separate concern, operator methods never count,
and block bodies are not traversed.

```yaml
Kaizo/NestedMethodCalls:
  Max: 1            # default; raise to allow deeper nesting
  AllowedMethods:
    - expect        # e.g. don't count RSpec's expect(...) wrapper
```

## Comments in specs

`Kaizo/SpecComment` flags comments in spec files: a sentence explaining an
example usually wants to be a `context`/`it` description, a clearer example
name, or another example.

```ruby
# bad
it 'permits the request' do
  # an admin can see everything
  user = create(:user, admin: true)
  expect(policy).to permit(user)
end

# good
it 'permits an admin to see everything' do
  admin = create(:user, admin: true)
  expect(policy).to permit(admin)
end
```

Only `*_spec.rb` files are inspected; `spec/helpers/` and `spec/support/`
hold infrastructure, not specs, and are excluded by default. Magic comments,
`# rubocop:` directives, and shebangs are never flagged.

```yaml
Kaizo/SpecComment:
  inherit_mode:
    merge:
      - Include
  Include:
    - '**/spec/**/*'     # spec_helper, support/, factories
    - '**/*_test.rb'     # Minitest / Test::Unit
  Exclude: []            # police spec/helpers and spec/support too
  AllowedPatterns:
    - '\A#\s*@rbs'       # permit rbs-inline type annotations
```

## Spec description prose

`Kaizo/SpecDescriptionProse` requires `it`/`context` descriptions to read as
one-behavior prose. Every rule is structural — it fires only when the wording
signals that one example is really several, or that the assertion is leaking
into the name.

```ruby
# bad
it "renders the name, image, and flag"     # a comma joins several behaviors
it "omits the key when the role is unset"  # a condition belongs in a context
it "renders the :cpu member"               # code is not prose
context "the role is unset" do             # contexts open with when/with/without/after
end

# good
it "renders the name"
it "renders the cpu member"
it "raises Timeout::Error"
context "when the role is unset" do
  it "omits the key"
end
```

`describe` strings name the unit under test and are exempt. So is an error
class name (`raises Timeout::Error` above) — the error is what the user
ultimately sees, so it *is* the specified behavior. The `ForbiddenWords`
defaults are curated, not exhaustive: `for` is a preposition in most
descriptions, and homographs like `given` collide with prose, so they are
left out — add them back if you want them:

```yaml
Kaizo/SpecDescriptionProse:
  inherit_mode:
    merge:
      - ForbiddenWords
      - AllowedPatterns
  ForbiddenWords:
    - given              # flag `given ...` descriptions too
  AllowedPatterns:
    - 'Foo::Widget'      # this one identifier is allowed anywhere
```

Before 0.9 these lists were named `Conjunctions` and `ContextPrefixes`; the
old keys are no longer read.

## Spec subject

`Kaizo/SpecSubject` requires the unit under test to be declared with
`subject`, not hidden in a `let` — `subject` is RSpec's name for the object
being specified, and declaring it unlocks `is_expected` one-liners.

```ruby
# bad
RSpec.describe Session::Pool do
  let(:pool) { described_class.new }
end

# good
RSpec.describe Session::Pool do
  subject(:pool) { described_class.new }
end
```

A `let` is flagged only when its block confidently builds the class under
test: a `.new` of `described_class`, of the constant an enclosing
`describe`/`context` names (full or short name), or of a constant matching
the spec's filename (`pool_spec.rb` names `Pool`). Deliberate second
instances are the escape hatch's job:

```yaml
Kaizo/SpecSubject:
  AllowedMethods:
    - other          # subject == other comparisons
  AllowedPatterns:
    - '\Aother_'
```

## Including FileUtils

`Kaizo/FileUtilsInclusion` flags a class or module (reported once) that
qualifies `FileUtils.` more than once: `include` it for instance-level use,
`extend` it for class-level use, and call the methods unqualified.

```ruby
# bad
class Backup
  def run
    FileUtils.mkdir_p(dir)
    FileUtils.cp(src, dir)
  end
end

# good
class Backup
  include FileUtils

  def run
    mkdir_p(dir)
    cp(src, dir)
  end
end
```

A single qualified call is left alone, a namespace already mixing in
`FileUtils` is not flagged, and nested classes are counted on their own.

## Prefer Pathname

`Kaizo/PreferPathname` flags `File` class methods with a `Pathname`
instance-method equivalent — once a path is a `Pathname`, calling the method
on it reads better than threading a string through `File`.

```ruby
# bad
File.read(path)
File.exist?(path)
File.join(dir, name)

# good
path.read
path.exist?
dir.join(name)
```

The banned set is the intersection of `File`'s class methods and `Pathname`'s
public instance methods, so `File.new` is left alone. A few equivalents are
not drop-in — `Pathname#join` treats an absolute segment as a reset,
`Pathname#chmod` acts on one receiver where `File.chmod` is variadic — which
is part of why there is no autocorrection. Executables often work with raw
path strings, so `exe/**/*` and `bin/**/*` are skipped by default:

```yaml
Kaizo/PreferPathname:
  Exclude:
    - 'exe/**/*'
    - 'bin/**/*'
    - 'db/**/*'      # add your own
```

## Temp files

`Kaizo/TempfileCreate` requires block-form `Tempfile.create` — the only
temp-file API whose cleanup is deterministic.

```ruby
# bad
file = Tempfile.new("report")     # removed in a GC finalizer, or never
file = Tempfile.open("report")    # the same finalizer gamble
file = Tempfile.create("report")  # a bare File that is never auto-removed

# good — closed and removed when the block returns, however it returns
Tempfile.create("report") do |file|
  file.write(data)
end
```

## Explicit begin

`Kaizo/ExplicitBegin` requires an explicit `begin`/`end` block when a method
body attaches `rescue`/`ensure` directly to the `def`: the `begin` marks
exactly what is guarded, so the method can grow without silently widening
what the `rescue` covers.

```ruby
# bad
def foo
  do_something
ensure
  cleanup
end

# good
def foo
  begin
    do_something
  ensure
    cleanup
  end
end
```

Modifier rescues (`foo rescue nil`) and endless definitions are not flagged.
This is the one cop that autocorrects (`rubocop -a`); the correction skips
single-line definitions and bodies holding heredocs or other multiline
literals, where re-indenting could change their contents.

Because core's `Style/RedundantBegin` enforces the exact opposite style,
loading this plugin disables it — otherwise the two autocorrections would
loop forever. To opt out of explicit begins, disable this cop — re-enabling
`Style/RedundantBegin` alone would leave both cops on, each flagging the form
the other mandates:

```yaml
Kaizo/ExplicitBegin:
  Enabled: false    # opt out of explicit begins
Style/RedundantBegin:
  Enabled: true     # optional: enforce the inverse style instead
```

## Next in value-returning blocks

`Kaizo/NextInNonVoidEnumerable` flags `next` inside the block of a
value-returning `Enumerable` method — `map`, `select`, `filter_map`,
`reduce`, `sum`, the `*_by` methods, the predicates — where `next` is
control flow being used as a value.

```ruby
# bad
array.map do |item|
  next if skip?(item)
  transform(item)
end

# bad — `next <value>` counts too
array.reduce(0) do |sum, item|
  next sum if skip?(item)
  sum + item
end

# good — a void iteration method; `next` just skips the iteration
array.each do |item|
  next if skip?(item)
  process(item)
end

# good — say what you mean
array.filter_map { |item| transform(item) unless skip?(item) }
```

Void iteration methods (`each`, `each_with_object`, ...) and non-`Enumerable`
loops (`loop`, `while`, `Integer#times`) are never flagged, and a `next`
bound to a nested block or loop is attributed to that inner scope.

```yaml
Kaizo/NextInNonVoidEnumerable:
  AllowedMethods:
    - reduce        # permit `next <acc>` guards in reduce/inject
```

## Plural names for collections

`Kaizo/PluralCollectionName` flags a method that hands back an array under a
singular name — `users` tells the caller what they are getting; `user`
actively misleads them.

```ruby
# bad
def user
  [first_match, second_match]
end

# good
def users
  [first_match, second_match]
end

# good — not confidently a collection (one branch is not an array), so the
# cop deliberately errs toward silence
def user
  return nil if missing?

  [first_match, second_match]
end
```

A method is flagged only when every value it can return is unambiguously an
array: a literal, or a call to an `ArrayMethods` entry. `select`/`reject` are
absent from that default on purpose — on a `Hash` they return a `Hash`. A
name counts as plural when it ends in `s` or appears in `IrregularPlurals`;
predicates, writers, operators, and `initialize` are exempt.

```yaml
Kaizo/PluralCollectionName:
  inherit_mode:
    merge:
      - ArrayMethods
      - IrregularPlurals
  ArrayMethods:
    - fetch_all     # your own collection-returning helper
  IrregularPlurals:
    - alumni        # plural without a trailing `s`
```

## Development

```bash
bin/setup                 # install dependencies
bundle exec rake          # run specs + self-lint
bundle exec rake spec     # specs only
```

## License

Available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
