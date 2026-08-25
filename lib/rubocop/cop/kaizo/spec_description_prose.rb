module RuboCop
  module Cop
    module Kaizo
      # Requires RSpec `it`/`context` descriptions to read as one-behavior prose
      # specifications, after the spec-skeleton naming law.
      #
      # An `it`/`specify`/`example` description must not contain a comma (a list
      # is several behaviors), a forbidden word (`ForbiddenWords` -- conjunctions
      # join clauses that are separate examples; a conditional signals a hidden
      # `context`), or code (`_ : # = { } ! [ ]`, a backtick, or a nested quoted
      # literal -- a description is prose, not identifiers or wire values). Each
      # rule is structural: it signals that one example is really more than one,
      # or that the assertion is leaking into the name.
      #
      # A `context` description must not contain code, and must open with one of
      # `RequiredContextPrefixes` (`when`/`with`/`without`/`after`). `describe`
      # strings name the unit under test and are exempt. An error class name
      # (`Foo::Error`, `Timeout::DeadlineException`) reads as prose, not code:
      # the error is part of the specified behavior and is what the user
      # ultimately sees raised.
      #
      # Wording preferences that do not change the spec's structure (e.g. `should`
      # vs a present-tense verb) are out of scope -- see rubocop-rspec's
      # `RSpec/ExampleWording`.
      #
      # There is no autocorrection: splitting an example, or extracting a
      # condition into a `context`, is a modelling decision for a human.
      #
      # == Configuration
      #
      # [+ForbiddenWords+] Words that force a split when they appear in an
      #                    example description, matched as whole words, case
      #                    insensitively. Default: +and+, +but+, +or+, +nor+,
      #                    +so+, +yet+, +when+, +whenever+, +if+, +unless+,
      #                    +while+, +until+, +because+, +although+, +though+.
      # [+RequiredContextPrefixes+] Words a `context` description may open
      #                             with. Default: +when+, +with+, +without+,
      #                             +after+.
      # [+AllowedPatterns+] Regexps matched against the whole description; a
      #                     match exempts it from every rule. The escape hatch
      #                     for a description that must quote something
      #                     code-shaped. Default: none.
      # [+Include+] Files the cop runs on. Default: <tt>**/*_spec.rb</tt>.
      #
      #   Kaizo/SpecDescriptionProse:
      #     inherit_mode:
      #       merge:
      #         - ForbiddenWords
      #         - AllowedPatterns
      #     ForbiddenWords:
      #       - given            # flag `given ...` too
      #     AllowedPatterns:
      #       - 'Foo::Widget'    # allow this one identifier
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
        include AllowedPattern

        EXAMPLE_METHODS = %i[
          it specify example fit xit fspecify xspecify fexample xexample
        ].freeze
        CONTEXT_METHODS = %i[context fcontext xcontext].freeze
        RESTRICT_ON_SEND = (EXAMPLE_METHODS + CONTEXT_METHODS).freeze

        COMMA_MSG = "Split this example: its description contains a comma.".freeze
        FORBIDDEN_WORD_MSG = "Split this example: its description contains `%<word>s`; " \
                             "use separate examples or a `context`.".freeze
        CODE_MSG = "Write the description as prose; it contains code, not English.".freeze
        CONTEXT_CODE_MSG = "Write the context description as prose; it contains code, not English.".freeze
        CONTEXT_PREFIX_MSG = "Begin the context description with %<prefixes>s.".freeze

        # Coordinating (FANBOYS, minus the preposition-heavy `for`) plus the
        # conditional subordinators that reliably signal a hidden "given".
        # Homographs like `even`/`given`/`regardless` are deliberately absent --
        # they collide with adjectives/nouns (`even numbers`) -- add them via
        # config if you want them.
        DEFAULT_FORBIDDEN_WORDS = %w[
          and but or nor so yet
          when whenever if unless while until because although though
        ].freeze
        DEFAULT_REQUIRED_CONTEXT_PREFIXES = %w[when with without after].freeze

        CODE_CHARS = /[_:#={}!`\[\]]/
        NESTED_QUOTE = /(['"]).+\1/

        # An error class name is part of the specified behavior -- it is what
        # the user sees raised -- so it is masked to prose before the checks.
        ERROR_CONSTANT = /(?:::)?\b(?:[A-Z]\w*::)*(?:[A-Z]\w*)?(?:Error|Exception)\b/

        # @!method description(node)
        def_node_matcher :description, <<~PATTERN
          (send nil? _ (str $_) ...)
        PATTERN

        def on_send(node)
          text = description(node)
          return unless text
          return if matches_allowed_pattern?(text)

          message = violation(node.method_name, without_error_constants(text))
          return unless message

          add_offense(node.first_argument, message:)
        end

        private

        def without_error_constants(text)
          text.gsub(ERROR_CONSTANT, "error")
        end

        def violation(method, text)
          if EXAMPLE_METHODS.include?(method)
            example_violation(text)
          else
            context_violation(text)
          end
        end

        def example_violation(text)
          return COMMA_MSG if text.include?(",")

          word = forbidden(text, forbidden_words)
          return format(FORBIDDEN_WORD_MSG, word:) if word

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
          /\A\s*(?:#{required_context_prefixes.map { |prefix| Regexp.escape(prefix) }.join("|")})\b/i
        end

        def quoted_prefixes
          required_context_prefixes.map { |prefix| "`#{prefix}`" }.join("/")
        end

        def forbidden_words
          cop_config.fetch("ForbiddenWords", DEFAULT_FORBIDDEN_WORDS)
        end

        def required_context_prefixes
          cop_config.fetch("RequiredContextPrefixes", DEFAULT_REQUIRED_CONTEXT_PREFIXES)
        end
      end
    end
  end
end
