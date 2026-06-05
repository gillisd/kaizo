# Changelog

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
