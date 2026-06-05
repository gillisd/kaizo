# RuboCop::Design

A [RuboCop](https://rubocop.org) extension whose cops pressure better object and
domain design — bounding how many arguments a method declares, and flagging class
names that describe an action rather than the concept they model.

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
| `Design/PositionalArguments` | positional params | `arg`, `optarg` |
| `Design/KeywordArguments` | keyword params | `kwarg`, `kwoptarg` |
| `Design/TotalArguments` | positional + keyword | all of the above |

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

Beyond argument counts, the gem ships **`Design/AgentNounClassName`**, which
flags classes named after what they *do* — see [Class naming](#class-naming).

## Installation

Add to your `Gemfile`:

```ruby
gem 'rubocop-design', require: false
```

Enable the plugin in `.rubocop.yml`:

```yaml
plugins:
  - rubocop-design
```

(Requires RuboCop 1.72.2+ for the `lint_roller` plugin API.)

## Configuration

The defaults are deliberately strict — **at most one positional and one keyword
argument** — to apply maximum pressure toward modeling. Loosen them if that is
too aggressive for your codebase:

```yaml
Design/PositionalArguments:
  Max: 1        # default
Design/KeywordArguments:
  Max: 1        # default
Design/TotalArguments:
  Max: 2        # default (one positional + one keyword)
```

Setting `Max: 0` forbids a kind of argument entirely — for example, banning
positional arguments so that every parameter must be passed by keyword:

```yaml
Design/PositionalArguments:
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
parameter list. `rubocop-design` is more granular: it bounds positional and
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

`Design/AgentNounClassName` flags classes named as agent nouns — "doers" —
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
Design/AgentNounClassName:
  inherit_mode:
    merge:
      - AllowedSuffixes
      - ForbiddenSuffixes
  AllowedSuffixes:
    - Ledger      # OrderLedger now passes
  ForbiddenSuffixes:
    - Server      # ApiServer now flagged, despite the default allowance
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
