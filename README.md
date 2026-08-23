# Kaizo

A strict, punishing [RuboCop](https://rubocop.org) extension aimed at
AI-agent-authored Ruby — holding generated code to a demanding design bar by
bounding how many arguments a method declares, flagging class names that
describe an action rather than the concept they model, flagging method calls
nested too deeply in other calls' arguments, and treating comments and loose
descriptions in specs as prose that should become structure.

_Kaizo_ (改造) — "remodeling", "modification": the ruleset keeps applying
pressure until the code is remade into something better.

A long argument list is a smell: it usually means a method is juggling loose
primitives that want to be modeled as an object. By putting a ceiling on the
number of arguments, these cops apply steady pressure toward naming the
abstraction — an entity, a value object, a parameter object — instead of
threading five primitives through a signature.

```ruby
# bad
def calculate_volume(width, length, height, shape_type)
end

# good
def calculate_volume(shape)
end
```

## Cops

| Cop | Bounds | Counts |
|-----|--------|--------|
| `Kaizo/PositionalArguments` | positional params | `arg`, `optarg` |
| `Kaizo/KeywordArguments` | keyword params | `kwarg`, `kwoptarg` |
| `Kaizo/TotalArguments` | positional + keyword | all of the above |

Each cop has a `Max` option. All three check `def`, `def self.`,
`define_method`, and `define_singleton_method`.

The three cops are independent and complementary — enable whichever dimensions
you want to bound. `TotalArguments` alone is a single global cap; pairing
`PositionalArguments` with `KeywordArguments` bounds each kind separately (so you
can, for instance, forbid positional arguments while allowing a couple of keyword
ones); running `TotalArguments` alongside them also catches methods that stay
under each per-kind limit but exceed the total. A method that breaks more than
one bound is reported once per cop it violates — by design — so enable the
smallest set that expresses your rule.

Beyond argument counts, the gem ships **`Kaizo/AgentNounClassName`**, which
flags classes named after what they *do* (see [Class naming](#class-naming)),
**`Kaizo/NestedMethodCalls`**, which flags calls buried too deeply in other
calls' arguments (see [Nested method calls](#nested-method-calls)),
**`Kaizo/SpecComment`**, which flags comments in spec files (see
[Comments in specs](#comments-in-specs)), **`Kaizo/SpecDescriptionProse`**,
which requires `it`/`context` descriptions to read as one-behavior prose (see
[Spec description prose](#spec-description-prose)), **`Kaizo/SpecSubject`**,
which requires the unit under test to be declared with `subject`, not `let`
(see [Spec subject](#spec-subject)),
**`Kaizo/FileUtilsInclusion`**, which asks you to `include`/`extend` `FileUtils`
once its methods are used more than once (see
[Including FileUtils](#including-fileutils)), **`Kaizo/PreferPathname`**, which
prefers `Pathname` over `File` for the operations `Pathname` provides (see
[Prefer Pathname](#prefer-pathname)), **`Kaizo/TempfileCreate`**, which
requires block-form `Tempfile.create` for temporary files (see
[Temp files](#temp-files)), **`Kaizo/ExplicitBegin`**, which requires
an explicit `begin` for method bodies that `rescue` or `ensure` (see
[Explicit begin](#explicit-begin)), and **`Kaizo/NextInNonVoidEnumerable`**,
which flags `next` used as control-flow-as-value inside `map`/`select`/`reduce`
blocks (see [Next in value-returning blocks](#next-in-value-returning-blocks)).

## Installation

Add to your `Gemfile`:

```ruby
gem 'kaizo', require: false
```

Enable the plugin in `.rubocop.yml`:

```yaml
plugins:
  - kaizo
```

(Requires RuboCop 1.72.2+ for the `lint_roller` plugin API.)

## Configuration

The defaults are deliberately strict — **at most one positional and one keyword
argument** — to apply maximum pressure toward modeling. Loosen them if that is
too aggressive for your codebase:

```yaml
Kaizo/PositionalArguments:
  Max: 1        # default
Kaizo/KeywordArguments:
  Max: 1        # default
Kaizo/TotalArguments:
  Max: 2        # default (one positional + one keyword)
```

Setting `Max: 0` forbids a kind of argument entirely — for example, banning
positional arguments so that every parameter must be passed by keyword:

```yaml
Kaizo/PositionalArguments:
  Max: 0        # every argument must be passed by keyword
```

### What is counted

Only **named, individual** parameters count toward the limits:

- Positional: required (`a`) and optional (`a = 1`).
- Keyword: required (`a:`) and optional (`a: 1`).

The variadic collectors `*rest`, `**keyword_rest`, `&block`, and `...` are **not**
counted — they are single tokens, not a list of primitives.

### Exemptions

The `initialize` of a `Struct.new` or `Data.define` block is exempt, because its
parameters mirror the value object's attributes — which is exactly the modeling
these cops are meant to encourage:

```ruby
# not flagged
Data.define(:width, :height, :depth, :weight) do
  def initialize(width:, height:, depth:, weight:)
    super
  end
end
```

**Operator methods** are exempt too. The arity of `[]=` is fixed by Ruby's syntax
— an index (or indices) plus the value being assigned — so there is no object to
extract and no primitive obsession to correct. The same holds for `[]`, `<=>`,
`+`, `<<`, `==`, and the rest of the operator family:

```ruby
# not flagged
def []=(row, column, value)
  @cells[row][column] = value
end
```

This covers `def`, `def self.`, and `define_method(:[]=)`. A `define_method` whose
name is computed at runtime is still checked — the cop cannot know what the name
resolves to. Note the exemption is for *operator* methods, not ordinary writers:
`def name=(value)` takes a single argument and was never in danger of tripping the
limits anyway.

Beyond the structural exemptions, all three cops take **`AllowedMethods`** and
**`AllowedPatterns`** — exempt individual methods by name or by regexp. The
classic case is `#initialize`: a constructor that legitimately gathers several
collaborators while every other method stays under a strict `Max`:

```yaml
Kaizo/KeywordArguments:
  Max: 1
  AllowedMethods:
    - initialize     # constructors may gather collaborators
Kaizo/PositionalArguments:
  AllowedPatterns:
    - '\Abuild_'     # or exempt a whole naming family
```

There is intentionally **no autocorrection**: the fix is a design decision (what
object should these arguments become?), and that belongs to a human.

## Relationship to `Metrics/ParameterLists`

Core RuboCop's `Metrics/ParameterLists` enforces a single maximum on the whole
parameter list. `kaizo` is more granular: it bounds positional and
keyword arguments separately (and together), and is framed around domain
modeling rather than method complexity. Use whichever fits; they can coexist.

For the full rationale — why the counting is implemented here rather than reusing
or configuring `Metrics/ParameterLists`, with reproducible evidence — see
[docs/why-not-metrics-parameterlists.md](docs/why-not-metrics-parameterlists.md).

## Known limitations

- **The proc/lambda form of `define_method` is not inspected.** Only the block
  form (`define_method(:foo) { |a, b| }`) is checked. When the body is supplied
  as a callable — `define_method(:foo, ->(a, b) {})` or
  `define_method(:foo, captured_method)` — it is left alone, because the argument
  may be any object that responds to `call` and is not statically countable in
  the general case.
- **Numbered and `it` block parameters count as zero.**
  `define_method(:squared) { _1 * _1 }` is treated as taking no arguments:
  implicit block parameters are not part of a declared signature, which is what
  these cops measure. Spell the parameters out if you want them counted.

## Class naming

`Kaizo/AgentNounClassName` flags classes named as agent nouns — "doers" —
rather than the domain concepts they model. A class whose name ends in `er`/`or`
(`OrderManager`, `PaymentProcessor`, `RequestHandler`), or in a configured
forbidden suffix like `Service`, usually means procedural behavior that wants a
clearer name or a different home.

```ruby
# bad
class PaymentProcessor
end

# good
class Payment
end
```

It checks `class` definitions and `Struct.new` / `Data.define` / `Class.new`
constant assignments. Like the argument-count cops, there is **no autocorrection** — a
rename is a design decision.

### Tuning the lists

Two suffix lists drive it, both fully configurable and matched against the last
segment of a namespaced name (`Billing::InvoiceBuilder` is checked as
`InvoiceBuilder`):

- **`AllowedSuffixes`** — exempt these. Matched as a suffix, so `Controller`
  clears `Controller` and `UsersController` alike. Ships with a broad default of
  legitimate `-er`/`-or` words — domain nouns (`Order`, `User`, `Number`,
  `Error`) and framework terms (`Controller`, `Serializer`, `Adapter`).
- **`ForbiddenSuffixes`** — always flag these, even when they don't end in
  `-er`/`-or` (default: `Service`, `Util`, `Utils`). This list **wins** over
  `AllowedSuffixes`, so it doubles as the way to drop a default exemption.

Extend either list without restating the default using RuboCop's `inherit_mode`:

```yaml
Kaizo/AgentNounClassName:
  inherit_mode:
    merge:
      - AllowedSuffixes
      - ForbiddenSuffixes
  AllowedSuffixes:
    - Ledger      # OrderLedger now passes
  ForbiddenSuffixes:
    - Server      # ApiServer now flagged, despite the default allowance
```

## Nested method calls

`Kaizo/NestedMethodCalls` flags method calls nested too deeply in **argument**
positions — `foo(SomeClass.new(another("bar").chain))` — on the principle that the
intermediate results want names. Reaching for the right name (or extracting a
method) almost always reads better, and is easier to debug, than peeling
parentheses apart.

The point is not the assignment, it is the **name**. A local called `result` or
`tmp` buys nothing; a name that says what the value *is* turns the step into its
own documentation.

```ruby
# bad
wrap(parse(read(io)))

# bad - named, but the name says nothing
result = parse(read(io))
wrap(result)

# good - the name documents what the value is
parsed_config = parse(read(io))
wrap(parsed_config)

# good - a single nested call is fine
puts compute(value)
```

Depth is bounded by `Max` (default `1` — one nested call is allowed). Only nesting
through **arguments** is counted; a *receiver chain* such as
`user.account.owner.name` is a separate concern (a dedicated chaining cop is
planned). Operator methods (`a + b`, `arr[i]`) never count, block bodies are not
traversed, and `AllowedMethods` exempts calls to named methods:

```yaml
Kaizo/NestedMethodCalls:
  Max: 1            # default; raise to allow deeper nesting
  AllowedMethods:
    - expect        # e.g. don't count RSpec's expect(...) wrapper
```

Like the other cops, there is **no autocorrection** — choosing the intermediate
name is a design decision.

## Comments in specs

`Kaizo/SpecComment` flags comments in spec files. A comment in a spec is almost
always a sign that the spec is doing the job of its own description: if you need a
sentence to explain what an example sets up or asserts, that sentence usually
wants to be a `context`/`it` description, a clearer example name, or another
example — not prose riding alongside the code.

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

By default only `*_spec.rb` files are inspected, and `spec/helpers/` and
`spec/support/` are excluded — those directories hold infrastructure, not
specs, and prose there is legitimate. Magic comments
(`# frozen_string_literal: true`, `# encoding: …`), RuboCop directives
(any `# rubocop:` comment), and shebangs are never flagged. Like
the other cops, there is **no autocorrection** — turning an explanation into a
spec is a design decision.

### Scope and escape hatches

The cop is scoped through the standard per-cop `Include`/`Exclude`, so broaden
it to cover support files or a Minitest suite (using `inherit_mode: merge` to
add to the default rather than replace it), or override the default exclusions
if you *do* want helper files policed:

```yaml
Kaizo/SpecComment:
  inherit_mode:
    merge:
      - Include
  Include:
    - '**/spec/**/*'     # spec_helper, support/, factories
    - '**/*_test.rb'     # Minitest / Test::Unit
  Exclude: []            # police spec/helpers and spec/support too
```

Permit specific comments with `AllowedPatterns` — regexps matched against the
full comment text, leading `#` included:

```yaml
Kaizo/SpecComment:
  AllowedPatterns:
    - '\A#\s*@rbs'       # rbs-inline type annotations
    - 'noqa'
```

## Spec description prose

`Kaizo/SpecDescriptionProse` requires RSpec `it`/`context` descriptions to read
as one-behavior prose specifications. Every rule is **structural** — it fires
only when the wording signals that one example is really more than one, or that
the assertion is leaking into the name.

An `it`/`specify`/`example` description must not contain:

- a **comma** — a list is several behaviors;
- a **forbidden word** (`and`, `or`, `so`, `when`, `if`, `unless`, … — the
  `ForbiddenWords` list) — joined clauses are separate examples, and a condition
  belongs in a `context`;
- **code** — `_ : # = { } ! [ ]`, a backtick, or a nested quoted literal;
  a description is prose, not identifiers or wire values.

A `context` description must not contain code, and must open with a word from
`RequiredContextPrefixes` (`when`/`with`/`without`/`after`). `describe` strings
name the unit under test and are exempt. So is an **error class name**:
`it "raises Foo::Error"` passes, because the error *is* part of the spec — it
is what the user ultimately sees raised. Any constant path ending in `Error` or
`Exception` reads as prose.

```ruby
# bad
it "renders the name, image, and flag"
it "omits the key when the role is unset"
it "renders the :cpu member"
context "the role is unset" do
end

# good
it "renders the name"
it "renders the cpu member"
context "when the role is unset" do
  it "omits the key"
end
```

The defaults are deliberately curated, not exhaustive: `for` is dropped from the
forbidden words (it is a preposition in nearly every description), and homographs
like `even`/`given`/`regardless` are left out (they collide with `even numbers`
and the like) — add them via `ForbiddenWords` if you want them. Pure **wording**
preferences that don't change structure (e.g. `should` vs a present-tense verb)
are out of scope — rubocop-rspec's `RSpec/ExampleWording` already covers those.
There is no autocorrection: splitting an example, or extracting a condition into
a `context`, is a modelling decision for a human.

When a description genuinely must quote something code-shaped, exempt it with
`AllowedPatterns` — regexps matched against the whole description — instead of
forking the rules:

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

(Before 0.9 the two lists were named `Conjunctions` and `ContextPrefixes` —
names that said nothing about how the filter worked. The old keys are no
longer read; rename them when upgrading.)

## Spec subject

`Kaizo/SpecSubject` requires the unit under test to be declared with `subject`,
not `let`. `subject` is RSpec's name for the object being specified; hiding it
in a `let` obscures which object the examples are about and forfeits
`is_expected` one-liners.

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

A `let` (or `let!`) is flagged only when its block **confidently builds the
class under test** — the final expression is a `.new` call on:

- `described_class`;
- the constant an enclosing `describe`/`context` names, by full
  (`Session::Pool`) or short (`Pool`) name;
- a constant matching the spec's file name (`pool_spec.rb` names `Pool`,
  `api_client_spec.rb` names `APIClient`) — which is how string-description
  specs are still covered.

A `let` that builds a *deliberate* second instance — the `other` in an equality
spec — is the escape hatch's job, matched against the `let` name:

```yaml
Kaizo/SpecSubject:
  AllowedMethods:
    - other          # subject == other comparisons
  AllowedPatterns:
    - '\Aother_'
```

As with the other spec cops there is **no autocorrection** — renaming the
helper every example refers to is the author's call.

## Including FileUtils

`Kaizo/FileUtilsInclusion` flags repeated qualified `FileUtils.` calls within a
class or module: once you reach for `FileUtils` more than once, `include` it (for
instance-level use) or `extend` it (for class/singleton-level use) and call its
methods unqualified.

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

The class or module is reported once. A single qualified call is left alone, a
namespace that already mixes `FileUtils` in is not flagged, and nested classes
and modules are counted on their own (one call in an outer class and one in a
nested class do not add up). As with most of the cops here, there is **no
autocorrection** — whether to `include` or `extend`, and where the mixin belongs,
is a design decision.
## Prefer Pathname

`Kaizo/PreferPathname` flags calls to `File` class methods that have a `Pathname`
instance-method equivalent — `File.read`, `File.exist?`, `File.join`,
`File.expand_path`, and the like. Once a path is a `Pathname`, calling the method
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

The banned set is the intersection of `File`'s class methods and `Pathname`'s own
public instance methods (so `File.new`, and `File.path` whose `Pathname#path`
equivalent is protected, are left alone).
The cop runs on `**/*.rb` and skips `exe/**/*` and `bin/**/*` by default —
executables often work with raw path strings — which you can adjust with the
standard `Include`/`Exclude` options:

```yaml
Kaizo/PreferPathname:
  Exclude:
    - 'exe/**/*'
    - 'bin/**/*'
    - 'db/**/*'      # add your own
```

Because the ban is broad, a few equivalents are not drop-in replacements:
`Pathname#join` treats an absolute segment as a reset (`Pathname("a").join("/b")`
is `/b`, where `File.join("a", "/b")` is `a/b`), `Pathname#chmod`/`chown`/`utime`
act on the single receiver (where `File.chmod` is variadic over many paths), and
`Pathname#split`/`rename` differ in return type and arity. The cop only points;
mind those differences when you rewrite — part of why it does not autocorrect.

As with most of the cops here, there is **no autocorrection** — rewriting
`File.read(path)` as `Pathname(path).read` changes the receiver and is a call for
a human.

## Temp files

`Kaizo/TempfileCreate` requires temporary files to be created with block-form
`Tempfile.create` — the only temp-file API whose cleanup is deterministic. The
block form closes **and removes** the file when the block returns, however it
returns. Everything else cleans up unpredictably or not at all:

- `Tempfile.new` (and `Tempfile.open`) remove the file in a GC finalizer that
  runs at some arbitrary later point — possibly never, if the process dies
  first;
- blockless `Tempfile.create` hands back a plain `File` that is **never**
  removed automatically.

```ruby
# bad
file = Tempfile.new("report")
file = Tempfile.open("report")
file = Tempfile.create("report")

# good
Tempfile.create("report") do |file|
  file.write(data)
end
```

As with most of the cops here, there is **no autocorrection** — moving the
file's users inside the block is a restructuring, and the block's return value
replaces the handle the old code held onto.

## Explicit begin

`Kaizo/ExplicitBegin` requires an explicit `begin`/`end` block when a method
body attaches a `rescue` or `ensure` directly to the `def` — Ruby's "implicit
begin". It is the inverse of core's `Style/RedundantBegin`. An explicit `begin`
names the guarded region and keeps it bounded: it marks exactly what the
`rescue`/`ensure` covers, so the method can grow other statements without
silently widening what is rescued.

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

Modifier rescues (`foo rescue nil`) and endless method definitions are not
flagged. Unlike the other cops, this one **does autocorrect** (`rubocop -a`) —
wrapping a body in `begin`/`end` is a mechanical fix, not a design decision. The
correction is skipped when the body does not sit on its own lines between `def`
and `end` (a single-line definition, say), or contains a heredoc or other
multiline string, symbol, or regexp literal, where re-indenting could change
their contents.

Because `Style/RedundantBegin` enforces the exact opposite style, loading this
plugin **disables it** by default — otherwise the two autocorrections would loop
forever, each undoing the other. Re-enable it explicitly in your `.rubocop.yml`
if you would rather not require explicit begins:

```yaml
Style/RedundantBegin:
  Enabled: true     # opt back out of Kaizo/ExplicitBegin
```

## Next in value-returning blocks

`Kaizo/NextInNonVoidEnumerable` flags `next` inside the block of a
value-returning `Enumerable` method — `map`, `select`, `filter_map`, `reduce`,
`sum`, `group_by`, the `*_by` methods, the `any?`/`all?`/`none?`/`one?`
predicates, and so on — where `next` is being used as control-flow-as-value.

```ruby
# bad
array.map do |item|
  next if skip?(item)
  transform(item)
end

# bad - `next <value>` counts too
array.reduce(0) do |sum, item|
  next sum if skip?(item)
  sum + item
end

# good - void iteration method; `next` just skips the iteration
array.each do |item|
  next if skip?(item)
  process(item)
end

# good - say what you mean
array.filter_map { |item| transform(item) unless skip?(item) }
```

Only *void* iteration methods — those whose block return value is ignored
(`each`, `each_with_index`, `each_slice`, `each_with_object`, `reverse_each`,
`cycle`, …) — are meant to use `next`, which is why they are absent from the
flagged set. Non-`Enumerable` looping constructs (`loop`, `Integer#times`,
`while`) are likewise never flagged. A `next` that binds to a nested block or
loop is attributed to that inner scope, so an inner `each { next }` or
`while … next … end` does not flag an outer `map`.

As with most of the cops here, there is **no autocorrection** — the right fix
depends on intent (a guard clause might become a ternary, a `select`/`reject`, a
`filter_map`, or a restructured block). Exempt specific methods with
`AllowedMethods` / `AllowedPatterns`:

```yaml
Kaizo/NextInNonVoidEnumerable:
  AllowedMethods:
    - reduce        # allow `next <acc>` guards in reduce/inject
  AllowedPatterns: []
```

## Plural names for collections

`Kaizo/PluralCollectionName` flags a method that hands back an array under a
singular name. The plural does the documenting for free — `users` tells the
caller what they are getting; `user` actively misleads them.

```ruby
# bad
def user
  [first_match, second_match]
end

# good
def users
  [first_match, second_match]
end
```

Ruby has no return types, so "returns an array" is a heuristic — and this cop
deliberately errs toward silence. A method is flagged only when **every** value
it can return is unambiguously an array: an array literal, or a call to a method
in `ArrayMethods` whose result is an `Array` whatever its receiver. A single
branch returning something else is enough to leave the method alone:

```ruby
# good - not confidently a collection, so not flagged
def user
  return nil if missing?

  [first_match, second_match]
end
```

`select` and `reject` are absent from the default `ArrayMethods` on purpose: on a
`Hash` they return a `Hash`, and including them would turn this into a
false-positive mill. A name counts as plural when it ends in `s` or appears in
`IrregularPlurals`. Predicate (`?`), writer (`=`), and operator methods are
exempt, as is `initialize`.

All three lists are configurable — extend them without restating the defaults
via `inherit_mode: merge`:

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
  AllowedMethods: []
```

As with the other cops there is **no autocorrection** — only the author knows
the right plural.

## Development

```bash
bin/setup                 # install dependencies
bundle exec rake          # run specs + self-lint
bundle exec rake spec     # specs only
```

## License

Available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
