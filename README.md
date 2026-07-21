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
calls' arguments (see [Nested method calls](#nested-method-calls)), and
**`Kaizo/SpecComment`**, which flags comments in spec files (see
[Comments in specs](#comments-in-specs)), **`Kaizo/SpecDescriptionProse`**,
which requires `it`/`context` descriptions to read as one-behavior prose (see
[Spec description prose](#spec-description-prose)), and
**`Kaizo/PreferPathname`**, which prefers `Pathname` over `File` for the
operations `Pathname` provides (see [Prefer Pathname](#prefer-pathname)).

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

There is intentionally **no autocorrection**: the fix is a design decision (what
object should these arguments become?), and that belongs to a human.

## Relationship to `Metrics/ParameterLists`

Core RuboCop's `Metrics/ParameterLists` enforces a single maximum on the whole
parameter list. `kaizo` is more granular: it bounds positional and
keyword arguments separately (and together), and is framed around domain
modeling rather than method complexity. Use whichever fits; they can coexist.

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

```ruby
# bad
wrap(parse(read(io)))

# good - name the intermediate result
parsed = parse(read(io))
wrap(parsed)

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

By default only `*_spec.rb` files are inspected. Magic comments
(`# frozen_string_literal: true`, `# encoding: …`), RuboCop directives
(any `# rubocop:` comment), and shebangs are never flagged. Like
the other cops, there is **no autocorrection** — turning an explanation into a
spec is a design decision.

### Scope and escape hatches

The cop is scoped through its `Include`, so broaden it to cover support files or a
Minitest suite (using `inherit_mode: merge` to add to the default rather than
replace it):

```yaml
Kaizo/SpecComment:
  inherit_mode:
    merge:
      - Include
  Include:
    - '**/spec/**/*'     # spec_helper, support/, factories
    - '**/*_test.rb'     # Minitest / Test::Unit
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
- a **conjunction** (`and`, `or`, `so`, `when`, `if`, `unless`, … — the
  `Conjunctions` list) — joined clauses are separate examples, and a condition
  belongs in a `context`;
- **code** — `_ : # = { } ! [ ]`, a backtick, or a nested quoted literal;
  a description is prose, not identifiers or wire values.

A `context` description must not contain code, and must open with a word from
`ContextPrefixes` (`when`/`with`/`without`/`after`). `describe` strings name the
unit under test and are exempt.

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
conjunctions (it is a preposition in nearly every description), and homographs
like `even`/`given`/`regardless` are left out (they collide with `even numbers`
and the like) — add them via `Conjunctions` if you want them. Pure **wording**
preferences that don't change structure (e.g. `should` vs a present-tense verb)
are out of scope — rubocop-rspec's `RSpec/ExampleWording` already covers those.
There is no autocorrection: splitting an example, or extracting a condition into
a `context`, is a modelling decision for a human.

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

## Development

```bash
bin/setup                 # install dependencies
bundle exec rake          # run specs + self-lint
bundle exec rake spec     # specs only
```

## License

Available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
