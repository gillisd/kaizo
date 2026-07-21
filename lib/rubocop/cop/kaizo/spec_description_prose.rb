module RuboCop
  module Cop
    module Kaizo
      # Requires RSpec `it`/`context` descriptions to read as one-behavior prose
      # specifications, after the spec-skeleton naming law.
      #
      # An `it`/`specify`/`example` description must not contain a comma (a list
      # is several behaviors), a coordinating or conditional conjunction
      # (`Conjunctions` -- joined clauses are separate examples; a condition
      # belongs in a `context`), or code (`_ : # = { } ! [ ]`, a backtick, or a
      # nested quoted literal -- a description is prose, not identifiers or wire
      # values). Each rule is structural: it signals that one example is really
      # more than one, or that the assertion is leaking into the name.
      #
      # A `context` description must not contain code, and must open with one of
      # `ContextPrefixes` (`when`/`with`/`without`/`after`). `describe` strings
      # name the unit under test and are exempt.
      #
      # Wording preferences that do not change the spec's structure (e.g. `should`
      # vs a present-tense verb) are out of scope -- see rubocop-rspec's
      # `RSpec/ExampleWording`.
      #
      # There is no autocorrection: splitting an example, or extracting a
      # condition into a `context`, is a modelling decision for a human.
      #
      # @example
      #   # bad
      #   it "renders the name, image, and flag"
      #   it "omits the key when the role is unset"
      #   it "renders the :cpu member"
      #   context "the role is unset" do
      #   end
      #
      #   # good
      #   it "renders the name"
      #   it "renders the cpu member"
      #   context "when the role is unset" do
      #     it "omits the key"
      #   end
      #
      class SpecDescriptionProse < Base
        EXAMPLE_METHODS = %i[
          it specify example fit xit fspecify xspecify fexample xexample
        ].freeze
        CONTEXT_METHODS = %i[context fcontext xcontext].freeze
        RESTRICT_ON_SEND = (EXAMPLE_METHODS + CONTEXT_METHODS).freeze

        COMMA_MSG = "Split this example: its description contains a comma.".freeze
        CONJUNCTION_MSG = "Split this example: its description contains `%<word>s`; " \
                          "use separate examples or a `context`.".freeze
        CODE_MSG = "Write the description as prose; it contains code, not English.".freeze
        CONTEXT_CODE_MSG = "Write the context description as prose; it contains code, not English.".freeze
        CONTEXT_PREFIX_MSG = "Begin the context description with %<prefixes>s.".freeze

        # Coordinating (FANBOYS, minus the preposition-heavy `for`) plus the
        # conditional subordinators that reliably signal a hidden "given".
        # Homographs like `even`/`given`/`regardless` are deliberately absent --
        # they collide with adjectives/nouns (`even numbers`) -- add them via
        # config if you want them.
        DEFAULT_CONJUNCTIONS = %w[
          and but or nor so yet
          when whenever if unless while until because although though
        ].freeze
        DEFAULT_CONTEXT_PREFIXES = %w[when with without after].freeze

        CODE_CHARS = /[_:#={}!`\[\]]/
        NESTED_QUOTE = /(['"]).+\1/

        # @!method description(node)
        def_node_matcher :description, <<~PATTERN
          (send nil? _ (str $_) ...)
        PATTERN

        def on_send(node)
          text = description(node)
          return unless text

          message = violation(node.method_name, text)
          return unless message

          add_offense(node.first_argument, message: message)
        end

        private

        def violation(method, text)
          if EXAMPLE_METHODS.include?(method)
            example_violation(text)
          else
            context_violation(text)
          end
        end

        def example_violation(text)
          return COMMA_MSG if text.include?(",")

          word = forbidden(text, conjunctions)
          return format(CONJUNCTION_MSG, word: word) if word

          CODE_MSG if code?(text)
        end

        def context_violation(text)
          return CONTEXT_CODE_MSG if code?(text)
          return if text.match?(prefix_regexp)

          format(CONTEXT_PREFIX_MSG, prefixes: quoted_prefixes)
        end

        def code?(text)
          CODE_CHARS.match?(text) || NESTED_QUOTE.match?(text)
        end

        def forbidden(text, words)
          words.find { |word| text.match?(/\b#{Regexp.escape(word)}\b/i) }
        end

        def prefix_regexp
          /\A\s*(?:#{context_prefixes.map { |prefix| Regexp.escape(prefix) }.join("|")})\b/i
        end

        def quoted_prefixes
          context_prefixes.map { |prefix| "`#{prefix}`" }.join("/")
        end

        def conjunctions
          cop_config.fetch("Conjunctions", DEFAULT_CONJUNCTIONS)
        end

        def context_prefixes
          cop_config.fetch("ContextPrefixes", DEFAULT_CONTEXT_PREFIXES)
        end
      end
    end
  end
end
