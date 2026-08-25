# Changelog

## 0.9.1

- Rewrite the README example-first: every cop section leads with its bad/good
  example, a fourteen-cop table replaces the catalog paragraph, a real
  `rubocop --only Kaizo` transcript opens the document, and the enablement
  policy is stated plainly (every cop ships enabled; the plugin's only
  out-of-department change is disabling `Style/RedundantBegin`).
- Verify the README in CI: `spec/readme_examples_spec.rb` executes every
  example against the shipped config — bad code must be flagged by the cop
  its marker names, good code must pass the whole department, YAML fences
  must parse into real cops with shipped option keys, suffix claims run with
  the documented merge applied, the console transcript is re-derived from the
  cops, and every cop must have both a bad and a good example.
- Fix two rdoc errors found in review: `Kaizo/AgentNounClassName`'s
  `inherit_mode` example was a no-op (`Ledger` is already a default), and
  `Kaizo/ExplicitBegin`'s docs called re-enabling `Style/RedundantBegin` an
  opt-out when it leaves both cops fighting; the opt-out is disabling
  `Kaizo/ExplicitBegin`.

## 0.9.0

- Add `Kaizo/TempfileCreate` cop: requires temporary files to be created with
  block-form `Tempfile.create`, the only temp-file API whose cleanup is
  deterministic (the block closes and removes the file when it returns).
  `Tempfile.new` and `Tempfile.open` are flagged — their cleanup rides on a GC
  finalizer that may run late or never — as is blockless `Tempfile.create`,
  which returns a plain `File` that is never removed automatically. A
  block-pass argument (`Tempfile.create("x", &writer)`) counts as a block. No
  autocorrection. Enabled by default.
- Add `Kaizo/SpecSubject` cop: requires the unit under test to be declared with
  `subject`, not `let`. A `let`/`let!` is flagged when its block confidently
  builds the class under test — a `.new` on `described_class`, on the constant
  an enclosing `describe`/`context` names (full or short name), or on a
  constant matching the spec's file name (`pool_spec.rb` names `Pool`,
  `api_client_spec.rb` names `APIClient`). Deliberate second instances (an
  `other` in an equality spec) are exempted with `AllowedMethods` /
  `AllowedPatterns`, matched against the `let` name. Runs on `**/*_spec.rb`.
  No autocorrection. Enabled by default.
- `Kaizo/SpecComment` no longer inspects `spec/helpers` or `spec/support` by
  default: those directories hold infrastructure, not specs, and prose there is
  legitimate. The exclusion is plain per-cop `Exclude` configuration, so
  override it (`Exclude: []`) to police them again, or broaden/narrow the scope
  with the standard `Include`/`Exclude` as before.
- `Kaizo/SpecDescriptionProse` no longer flags error class names in
  descriptions: `it "raises Foo::Error"` passes, because the error is part of
  the specified behavior — it is what the user ultimately sees raised. Any
  constant path whose final segment ends in `Error` or `Exception` reads as
  prose; the rest of the description is still checked.
- `Kaizo/SpecDescriptionProse` gains `AllowedPatterns`: regexps matched against
  the whole description that exempt it from every rule — the ad-hoc escape
  hatch for a description that must quote something code-shaped.
- **Renamed** `Kaizo/SpecDescriptionProse`'s options: `Conjunctions` is now
  `ForbiddenWords` and `ContextPrefixes` is now `RequiredContextPrefixes`. The
  old names said nothing about whether the lists include or exclude, or how
  the filter works; the new ones do. This is a clean break: the old keys are
  no longer read — RuboCop warns that the parameter is unsupported and the
  shipped defaults apply — so rename them when upgrading.
- The argument-counting cops (`Kaizo/PositionalArguments`,
  `Kaizo/KeywordArguments`, `Kaizo/TotalArguments`) gain `AllowedMethods` and
  `AllowedPatterns`: exempt individual methods by name or regexp — e.g. allow
  `#initialize` to gather collaborators while everything else stays under a
  strict `Max`. Covers `def`, `def self.`, and the symbol/string
  `define_method` forms.
- `Kaizo/PluralCollectionName`'s `ArrayMethods` list is now genuinely
  configurable (the README already described it as such); the default list is
  spelled out in the shipped config so `inherit_mode: merge` can extend it.
- Every cop's rdoc header now carries a `== Configuration` section documenting
  each option, its semantics, and its default, with a ready-to-paste
  `.rubocop.yml` snippet — the config plane was previously undocumented at the
  class level.

## 0.8.0

- Add `Kaizo/PluralCollectionName` cop: flags a method that returns an array
  under a singular name (`def user` handing back `[first, second]`), since a
  plural name documents what the caller gets. Ruby has no return types, so the
  detection is a heuristic and errs toward silence — a method is flagged only
  when every value it can return is unambiguously an array, so one branch
  returning `nil` keeps it quiet. `ArrayMethods` covers calls whose result is an
  `Array` whatever the receiver; `select` and `reject` are excluded on purpose,
  since on a `Hash` they return a `Hash`. Predicate, writer, and operator
  methods are exempt, as is `initialize`. `IrregularPlurals` handles plurals
  without a trailing `s`. No autocorrection. Enabled by default.
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
- Expanded the `Kaizo/NestedMethodCalls` README guidance to spell out that the
  *name* is the point, not the assignment — extracting to a local called `result`
  or `tmp` satisfies the rule while missing what it asks for. The offense message
  itself is unchanged.

## 0.7.0

- No user-facing changes. Internal tooling and gem metadata only — nothing in
  the shipped cops or their configuration differed from 0.6.0.

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
