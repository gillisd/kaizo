# Changelog

## Unreleased

- The argument-counting cops (`Kaizo/PositionalArguments`, `Kaizo/TotalArguments`,
  `Kaizo/KeywordArguments`) no longer flag **operator methods**. The arity of `[]=`
  is fixed by Ruby's syntax — an index (or indices) plus the assigned value — so it
  cannot be modeled away; the same holds for `[]`, `<=>`, `+`, `<<`, `==`, and the
  rest of the operator family. Covers `def`, `def self.`, and the
  `define_method(:[]=)` form; a `define_method` whose name is computed at runtime is
  still checked, since the name cannot be known statically. This joins the existing
  `Struct.new`/`Data.define` `initialize` exemption. Ordinary writers
  (`def name=(value)`) are unaffected.
- The Public Config now ships `Style/HashSyntax` with
  `EnforcedShorthandSyntax: always`, preferring Ruby 3.1's hash-value shorthand
  (`Session.new(table:)` over `Session.new(table: table)`). Override it in your own
  config if you want the explicit form. *(Landed on `master` after 0.7.0 was
  published, so it has not reached gem users yet and was never recorded here.)*
- Reworded the `Kaizo/NestedMethodCalls` message to stress that the *name* is the
  point, not the assignment: "Avoid nesting method calls in arguments; name the
  intermediate result to document what it is." Extracting to a local called
  `result` or `tmp` satisfies the letter of the old message while missing what it
  was asking for.

## 0.6.0

- **Renamed the gem from `rubocop-design` to `kaizo`**, and moved every cop from
  the `Design/` department into `Kaizo/`: `Design/PositionalArguments` is now
  `Kaizo/PositionalArguments`, `Design/SpecComment` is now `Kaizo/SpecComment`,
  and so on for every cop. This is a pure rename — no cop logic, thresholds, or
  messages changed. Update your `Gemfile` (`gem 'kaizo'`), your `.rubocop.yml`
  `plugins:` entry (`- kaizo`), and any cop names in your configuration.
- Add `Kaizo/SpecDescriptionProse` cop: requires RSpec `it`/`context`
  descriptions to read as one-behavior prose. An `it` description may not contain
  a comma, a conjunction (`Conjunctions`), or code; a `context` description
  carries no code and must open with a `ContextPrefixes` word. `describe` strings
  are exempt. No autocorrection. Enabled by default.
- Add `Kaizo/FileUtilsInclusion` cop: requires `FileUtils` to be mixed in with
  `include`/`extend` once it is used more than once in a class or module, instead
  of repeating the `FileUtils.` receiver. A single qualified call, and a
  namespace that already mixes it in, are left alone; nested classes/modules are
  counted on their own. No autocorrection. Enabled by default.
- Add `Kaizo/PreferPathname` cop: flags calls to `File` class methods that have a
  `Pathname` instance-method equivalent (`File.read`, `File.exist?`, `File.join`,
  ...), preferring `Pathname`. Runs on `**/*.rb`; `exe/**/*` and `bin/**/*` are
  exempt by default (override with the standard `Include`/`Exclude`). No
  autocorrection. Enabled by default.
- Add `Kaizo/ExplicitBegin` cop: requires an explicit `begin`/`end` block when
  a method body attaches a `rescue` or `ensure` directly to the `def` (an
  "implicit begin") -- the inverse of `Style/RedundantBegin`. Modifier `rescue`
  (`foo rescue nil`) and endless method definitions are not flagged.
  Autocorrection wraps the body in `begin`/`end`, and is skipped only for
  single-line definitions and bodies holding heredocs or other multiline string
  literals, where re-indenting could change string contents. Enabled by default.
- Add `Kaizo/NextInNonVoidEnumerable` cop: flags `next` inside the block of a
  value-returning `Enumerable` method (`map`, `select`, `reduce`, and friends),
  where `next` is being used as control-flow-as-value. Void iteration methods
  (`each`, `each_with_object`, ...) and non-`Enumerable` loops (`loop`, `while`,
  `Integer#times`) are never flagged, and a `next` bound to a nested block or
  loop is attributed to that inner scope. Exempt methods with `AllowedMethods` /
  `AllowedPatterns`. No autocorrection. Enabled by default.
- Loading the plugin now disables core's `Style/RedundantBegin`, which enforces
  the opposite style; leaving both on would make their autocorrections loop.
  Re-enable it explicitly in your `.rubocop.yml` if you do not want
  `Kaizo/ExplicitBegin`.

## 0.5.0

- Add `Design/SpecComment` cop: flags comments in spec files (`**/*_spec.rb`),
  on the principle that a comment in a spec usually wants to be a `context`/`it`
  description or a better-structured example. Magic comments, `# rubocop:`
  directives, and shebangs are exempt; add more with `AllowedPatterns`. No
  autocorrection. Enabled by default.

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
