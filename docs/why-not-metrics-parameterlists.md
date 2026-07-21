# Why the argument cops don't use `Metrics/ParameterLists`

**Status:** rationale / design note
**Applies to:** `Kaizo/PositionalArguments`, `Kaizo/KeywordArguments`,
`Kaizo/TotalArguments`, and their shared `ArgumentCounting` module
([`lib/rubocop/cop/kaizo/argument_counting.rb`](../lib/rubocop/cop/kaizo/argument_counting.rb)).

## The question

Core RuboCop already ships `Metrics/ParameterLists`, which counts the parameters
in a method definition and flags a method with too many. This gem instead counts
arguments itself, in a hand-written `ArgumentCounting` module. Is that
reinventing the wheel? Is there a reason?

**Short answer:** the three `Kaizo/*` argument cops are not a reimplementation
of `Metrics/ParameterLists` — they express a rule that cop *structurally cannot
represent*. Core gives you **one** ceiling over a parameter list. This gem gives
you **three independent, composable ceilings** (positional, keyword, total),
counted by different rules, applied to a different set of nodes, and framed as
domain-design pressure rather than a complexity budget. Configuring, subclassing,
or re-enabling `Metrics/ParameterLists` cannot produce that behavior, so a small
amount of custom counting is unavoidable. The two are complementary and can
coexist.

The rest of this document is the deep dive, with reproducible evidence for every
claim.

---

## What each side actually does

### `Metrics/ParameterLists` (core)

Source: [`references/rubocop/lib/rubocop/cop/metrics/parameter_lists.rb`](../references/rubocop/lib/rubocop/cop/metrics/parameter_lists.rb).

- **One numeric ceiling, `Max`** (default `5`), checked in `on_args`.
- **`CountKeywordArgs`** (default `true`) — a *boolean* that only decides whether
  named keyword args are **included in or excluded from that single count**. It
  does not create a second, independent ceiling.
- **`MaxOptionalParameters`** (default `3`) — a *separate* sub-check, in
  `on_def`, on the number of optional (`optarg`) parameters only.
- `args_count` counts every child of the `args` node except the block arg — so
  `*rest` and `**kwrest` **do** count toward `Max` (only `&block` is excluded).
- It fires from `on_args`, i.e. on **every** argument list in the file except
  those directly belonging to a lambda/proc — including ordinary blocks.
- Department `Metrics` — a *complexity budget*, alongside `MethodLength`,
  `AbcSize`, `CyclomaticComplexity`.

### The `Kaizo/*` argument cops (this gem)

Source: [`argument_counting.rb`](../lib/rubocop/cop/kaizo/argument_counting.rb)
plus the three thin cop classes.

- **Three cops, three independent `Max` options.** `positional_arity` counts
  `arg`/`optarg`; `keyword_arity` counts `kwarg`/`kwoptarg`; `TotalArguments`
  sums the two. Each cop reads its own `Max`
  ([`argument_counting.rb:33-44`](../lib/rubocop/cop/kaizo/argument_counting.rb)).
- **Only four parameter types are ever counted:** `arg`, `optarg`, `kwarg`,
  `kwoptarg`. `*rest`, `**kwrest`, `&block`, forward-args, and numbered/`it`
  block params are **never** counted
  ([`POSITIONAL_TYPES`/`KEYWORD_TYPES`, lines 12-13](../lib/rubocop/cop/kaizo/argument_counting.rb)).
- **Only method *definitions* are inspected:** `def`, `def self.`,
  `define_method`, and `define_singleton_method` — nothing else
  ([`on_def`/`on_defs` and the `DEFINE_METHODS`-gated `on_block`, lines 18-29](../lib/rubocop/cop/kaizo/argument_counting.rb)).
- Deliberately strict defaults — `1` positional, `1` keyword, `2` total
  ([`config/default.yml:13-29`](../config/default.yml)) — versus core's `Max: 5`.
- Department `Kaizo` — *domain-modeling pressure*, framed by the README around
  turning primitive lists into an entity, value object, or parameter object.

---

## Reason 1 — one ceiling vs. three independent axes (the decisive one)

This is the whole reason the gem exists, and the one thing no configuration of
`Metrics/ParameterLists` can reproduce.

`Metrics/ParameterLists` has exactly one knob that varies a count: `Max`. The
`CountKeywordArgs` boolean does not add a second axis — it only slides keyword
args in or out of the *same* count. So the only rules it can express are:

- "at most N parameters, keyword args included" (`CountKeywordArgs: true`), or
- "at most N parameters, keyword args ignored entirely" (`CountKeywordArgs: false`).

There is **no** mode that isolates keyword args, and therefore no way to bound
positional and keyword arity *separately at the same time*. `Kaizo/KeywordArguments`
has no core equivalent whatsoever.

### Evidence

Goal: bound **keyword** args as their own dimension (`≤ 2`), regardless of how
many positional args a method has. A method with five keyword args should be
flagged; a method with a few positional args should be left alone.

```
kaizo  Kaizo/KeywordArguments Max 2:
   def m(k1:,k2:,k3:,k4:,k5:) -> FLAGGED  Method has too many keyword arguments. [5/2]
   def m(a,b,c)               -> allowed (keyword cop ignores positionals)

Metrics/ParameterLists — no config isolates keyword args:
   CountKeywordArgs=false, Max 2:  def m(k1:..k5:) -> allowed    def m(a,b,c) -> FLAGGED
   CountKeywordArgs=true,  Max 2:  def m(k1:..k5:) -> FLAGGED    def m(a,b,c) -> FLAGGED
```

- With `CountKeywordArgs: false`, the five-keyword method is **invisible** — a
  keyword explosion is never caught.
- With `CountKeywordArgs: true`, core catches the five-keyword method **only by
  also flagging** the three-positional one.

There is no third option. To express "generous with positionals, strict on
keywords" (or the reverse, or a per-kind split plus a total cap), you need
independent ceilings, which is exactly what the three cops provide. See the
README: *"forbid positional arguments while allowing a couple of keyword ones …
running `TotalArguments` alongside them also catches methods that stay under each
per-kind limit but exceed the total."*

### Why configuration can't rescue this

Even setting aside the missing keyword-only mode, RuboCop resolves configuration
**per cop name**: a cop class carries exactly one `cop_config` hash, so
`Metrics/ParameterLists` can hold exactly one `Max`. You cannot enable it three
times under three names with three limits. Reusing core's *logic* for three axes
would still require three distinct cop classes — and since core has no
keyword-only counting to reuse, those classes would have to count arguments
themselves anyway. That is precisely what the shared `ArgumentCounting` module
is: the minimum new code needed, written once and mixed into three one-line cops.

---

## Reason 2 — different counting rules (`*rest`, `**kwrest`, `&block`)

Even `Kaizo/TotalArguments` is **not** equivalent to `Metrics/ParameterLists`
with defaults, because they count different things. This gem counts only the four
"named slot" parameter types; core counts splat and double-splat too.

### Evidence

```
def m(a, b, *rest, **opts)          (2 named + splat + double-splat)
   Kaizo/TotalArguments (Max 2)  : no offense           # counts a, b = 2
   Metrics/ParameterLists (Max 2) : FLAGGED  [4/2]        # counts a, b, *rest, **opts = 4
```

**Rationale.** `*rest` and `**kwrest` denote *open-ended* arity — often a
forwarding or delegating method that has already collapsed its arguments into a
collection. Counting them works against the goal of these cops. The design smell
being pressured is "a signature carrying several *individually named* primitives
that want to become an object"; a splat is the opposite of that, so it is
excluded ([`total_arguments.rb:11-13`](../lib/rubocop/cop/kaizo/total_arguments.rb),
and the `does not count splat, double-splat, or block arguments` spec in
[`total_arguments_spec.rb`](../spec/rubocop/cop/kaizo/total_arguments_spec.rb)).

---

## Reason 3 — different node targeting (method definitions vs. every arg list)

`Metrics/ParameterLists` runs from `on_args`, so it inspects **every** parameter
list except a lambda/proc's — including ordinary blocks. These cops target
*method definitions* specifically: `def`, `def self.`, and the two dynamic
definers `define_method` / `define_singleton_method`. An ordinary block passed to
`each`/`map`/etc. is not inspected.

### Evidence

```
[1, 2].each { |a, b, c, d, e, f| nil }   (ordinary block, 6 params)
   Kaizo/TotalArguments (Max 2)  : no offense
   Metrics/ParameterLists (Max 2) : FLAGGED  [6/2]

define_method(:x) { |a, b, c| nil }      (dynamic method definition, 3 params)
   Kaizo/TotalArguments (Max 2)  : FLAGGED  [3/2]
   Metrics/ParameterLists (Max 2) : FLAGGED  [3/2]
```

**Rationale.** The smell these cops model is a *declared method signature*
(an object's named behavior) juggling too many primitives. A block yielded to an
iterator is a different construct — its parameter count is dictated by whatever
`yield`s to it, not by a design choice about an object's interface — so it is out
of scope. `define_method` **is** in scope precisely because it *does* define a
method. (See the `ignores ordinary blocks`, `checks define_method blocks`, and
`checks define_singleton_method blocks` specs in
[`total_arguments_spec.rb`](../spec/rubocop/cop/kaizo/total_arguments_spec.rb).)

---

## Reason 4 — different department, message, and defaults

Even where behavior overlaps, the *framing* is deliberately different, and
framing is a feature of a linter, not decoration:

| | `Metrics/ParameterLists` | `Kaizo/*Arguments` |
|---|---|---|
| Department | `Metrics` (complexity budget) | `Kaizo` (domain-modeling pressure) |
| Message | "Avoid parameter lists longer than N parameters." | "Method has too many positional/keyword arguments." |
| Default limit | `Max: 5` (loose) | `1` / `1` / `2` (deliberately strict) |
| Mental model | "this method is getting complex" | "these primitives want to be an object" |

Department placement changes how a team reasons about a violation and about
turning the cop off. A `Metrics` cop says *"reduce complexity."* A `Kaizo` cop,
with the README's `calculate_volume(width, length, height, shape_type)` →
`calculate_volume(shape)` example, says *"name the missing abstraction."* Same
mechanism (count arguments), different intent — and intent is what a design cop
is for. The strict `1/1/2` defaults express "apply maximum pressure toward
naming the abstraction," a posture that would be wrong for a general-purpose
complexity metric shipped to every RuboCop user.

---

## What the two intentionally share

The one place this gem re-derives behavior that core already has is the
**`Struct.new` / `Data.define` `initialize` exemption**. Both skip an
`initialize` whose enclosing block is a `Struct.new`/`Data.define`, because those
parameters mirror the value object's attributes and aren't a free design choice
([`allowed_initialize?`, `argument_counting.rb:54-70`](../lib/rubocop/cop/kaizo/argument_counting.rb);
core's `struct_new_or_data_define_block?`,
[`parameter_lists.rb:80-106`](../references/rubocop/lib/rubocop/cop/metrics/parameter_lists.rb)).
This parity is deliberate — a value object with five attributes shouldn't trip a
design cop any more than it trips the metric — and it is *not* a reason the cops
differ. It's called out here so a reader doesn't mistake it for the answer.

---

## Could we have reused core instead?

| Approach | Why it doesn't work |
|---|---|
| **Just configure `Metrics/ParameterLists`** | One `Max` + a boolean can't express independent positional/keyword/total ceilings, and can't isolate keyword args at all (Reason 1). |
| **Enable it three times under different names** | RuboCop keys config by cop name; a cop holds one `Max`. Not possible (Reason 1). |
| **Subclass `Metrics::ParameterLists` three times** | Its counting (`args_count`) has no keyword-only mode and counts `*rest`/`**kwrest`; you'd override the counting, the node handlers, the messages, and the department — i.e. rewrite it. The shared `ArgumentCounting` module *is* that rewrite, minus the parts that don't apply. |
| **Monkeypatch core** | Couples the gem to core's private internals across versions for no gain. |

The custom module is smaller and clearer than any of these, and it owns exactly
the four decisions that matter: which parameter types count, which nodes are
method definitions, the three per-axis limits, and the design-oriented message.

---

## Conclusion

`Metrics/ParameterLists` is a single-ceiling complexity metric. These cops are a
three-axis, domain-design instrument with different counting semantics, different
targeting, and different framing. The overlap (flagging a `def` with too many
plain positionals) is real but shallow; the parts that matter — per-kind bounds,
excluding open-ended arity, targeting only method definitions, and the
`Kaizo`-department framing — are things core neither does nor can be configured
to do. Hand-writing `ArgumentCounting` is the simplest correct way to get them.
Teams that also want the raw complexity signal can keep `Metrics/ParameterLists`
enabled alongside; the two are complementary.

---

## Reproducing the evidence

Every table above was produced by running both cops through RuboCop's own
`Commissioner` on identical source. With the bundle installed
(`bundle install`), a self-contained reproduction:

```ruby
# compare.rb — run with: bundle exec ruby compare.rb
require "rubocop"
require "kaizo"

def run(cop_class, config_hash, source)
  config = RuboCop::Config.new(
    { cop_class.cop_name => { "Enabled" => true }.merge(config_hash) }, "/tmp/.rubocop.yml"
  )
  cop = cop_class.new(config)
  report = RuboCop::Cop::Commissioner.new([cop])
                                     .investigate(RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f))
  report.offenses.reject(&:disabled?).map(&:message)
end

src = "def m(a, b, *rest, **opts)\nend\n"
p run(RuboCop::Cop::Kaizo::TotalArguments,       { "Max" => 2 }, src)                    # => []
p run(RuboCop::Cop::Metrics::ParameterLists,      { "Max" => 2, "CountKeywordArgs" => true }, src) # => ["Avoid parameter lists ... [4/2]"]
```

Verified against `rubocop 1.88.2` (see `Gemfile.lock`).
