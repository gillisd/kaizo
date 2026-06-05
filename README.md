# RuboCop::Arity

A [RuboCop](https://rubocop.org) extension that limits how many arguments a
method may declare.

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
| `Arity/PositionalArguments` | positional params | `arg`, `optarg` |
| `Arity/KeywordArguments` | keyword params | `kwarg`, `kwoptarg` |
| `Arity/TotalArguments` | positional + keyword | all of the above |

Each cop has independent `Min` and `Max` options. All three check `def`,
`def self.`, `define_method`, and `define_singleton_method`.

## Installation

Add to your `Gemfile`:

```ruby
gem 'rubocop-arity', require: false
```

Enable the plugin in `.rubocop.yml`:

```yaml
plugins:
  - rubocop-arity
```

(Requires RuboCop 1.72.2+ for the `lint_roller` plugin API.)

## Configuration

The defaults are deliberately strict — **at most one positional and one keyword
argument** — to apply maximum pressure toward modeling. Loosen them if that is
too aggressive for your codebase:

```yaml
Arity/PositionalArguments:
  Max: 1        # default
Arity/KeywordArguments:
  Max: 1        # default
Arity/TotalArguments:
  Max: 2        # default (one positional + one keyword)
```

`Min` (default `0`, which disables the lower bound) lets you require a floor —
for example, forbidding positional arguments while requiring keyword arguments:

```yaml
Arity/PositionalArguments:
  Max: 0        # forbid positional arguments entirely
Arity/KeywordArguments:
  Min: 1        # ...and require at least one keyword argument
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
parameter list. `rubocop-arity` is more granular: it bounds positional and
keyword arguments separately (and together), supports a lower bound, and is
framed around domain modeling rather than method complexity. Use whichever fits;
they can coexist.

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

## Development

```bash
bin/setup                 # install dependencies
bundle exec rake          # run specs + self-lint
bundle exec rake spec     # specs only
```

## License

Available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
