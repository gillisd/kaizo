# Changelog

## 0.1.0

Initial release.

- Add `Arity/PositionalArguments` cop: bounds the number of positional
  arguments (`Min`/`Max`).
- Add `Arity/KeywordArguments` cop: bounds the number of keyword arguments
  (`Min`/`Max`).
- Add `Arity/TotalArguments` cop: bounds the combined number of positional and
  keyword arguments (`Min`/`Max`).

All three cops check `def`, `def self.`, `define_method`, and
`define_singleton_method`, ignore `*rest`/`**kwargs`/`&block`, and exempt the
`initialize` of a `Struct.new`/`Data.define` block.
