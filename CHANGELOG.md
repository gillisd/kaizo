# Changelog

## 0.4.0

- Add `Design/NestedMethodCalls` cop: flags method calls nested too deeply in
  argument positions -- e.g. `foo(SomeClass.new(another("bar").chain))` -- on the
  principle that the intermediate results want names. Only argument nesting is
  counted (receiver chains are a separate concern); operator methods never count,
  and `AllowedMethods` exempts named methods. Bounded by `Max` (default 1). No
  autocorrection. Enabled by default.

## 0.3.0

- **Renamed the gem from `rubocop-arity` to `rubocop-design`**, and moved every
  cop into a single `Design/` department: `Arity/PositionalArguments`,
  `Arity/KeywordArguments`, and `Arity/TotalArguments` are now
  `Design/PositionalArguments`, `Design/KeywordArguments`, and
  `Design/TotalArguments`. Update your `Gemfile`, your `.rubocop.yml`
  `plugins:` entry, and any cop names in your configuration.

## 0.2.0

- Add `Design/AgentNounClassName` cop: flags classes named as agent nouns
  ("doers") — names ending in `er`/`or`, or in a configured `ForbiddenSuffixes`
  entry (default `Service`/`Util`/`Utils`) — unless they end in an
  `AllowedSuffixes` entry. Checks `class` definitions and
  `Struct.new`/`Data.define`/`Class.new` assignments. No autocorrection.

## 0.1.0

Initial release.

- Add `Arity/PositionalArguments` cop: bounds the number of positional
  arguments (`Max`).
- Add `Arity/KeywordArguments` cop: bounds the number of keyword arguments
  (`Max`).
- Add `Arity/TotalArguments` cop: bounds the combined number of positional and
  keyword arguments (`Max`).

All three cops check `def`, `def self.`, `define_method`, and
`define_singleton_method`, ignore `*rest`/`**kwargs`/`&block`, and exempt the
`initialize` of a `Struct.new`/`Data.define` block.
