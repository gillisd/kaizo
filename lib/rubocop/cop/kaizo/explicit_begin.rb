module RuboCop
  module Cop
    module Kaizo
      # Requires an explicit `begin`...`end` block when a method body has a
      # `rescue` or `ensure` clause, instead of attaching the clause directly
      # to the method definition (an "implicit begin"). This is the inverse
      # of `Style/RedundantBegin`, which kaizo's default configuration
      # disables so the two cops do not fight each other.
      #
      # An explicit `begin` names the unit of work being guarded, keeps the
      # rescue/ensure visually bound to it, and leaves room for the method to
      # grow other statements around the guarded region without silently
      # widening what the `rescue` covers.
      #
      # Modifier `rescue` expressions (`foo rescue nil`) and endless method
      # definitions are not flagged.
      #
      # == Configuration
      #
      # No cop-specific options; the standard per-cop settings (+Enabled+,
      # +Severity+, +AutoCorrect+, +Include+/+Exclude+) apply. Note that
      # loading the kaizo plugin disables `Style/RedundantBegin`, this cop's
      # exact inverse; re-enable that cop in your own configuration to opt out
      # of explicit begins.
      #
      # @safety
      #   Autocorrection is skipped when the body does not sit on its own lines
      #   between `def` and `end` (a single-line definition, for example), and
      #   for bodies containing heredocs or other multiline string, symbol, or
      #   regexp literals, because re-indenting those lines could change their
      #   contents.
      #
      # @example
      #   # bad
      #   def foo
      #     do_something
      #   ensure
      #     cleanup
      #   end
      #
      #   # good
      #   def foo
      #     begin
      #       do_something
      #     ensure
      #       cleanup
      #     end
      #   end
      #
      class ExplicitBegin < Base
        include Alignment
        include RangeHelp
        include RescueNode
        extend AutoCorrector

        MSG = "Use an explicit `begin` block for `rescue`/`ensure` in a method body.".freeze

        def on_def(node)
          return if node.endless?

          body = node.body
          return unless implicit_begin?(body)

          range = clause_keyword(body)
          if safe_to_correct?(node, body)
            add_offense(range) { |corrector| wrap_in_begin(corrector, node, body) }
          else
            add_offense(range)
          end
        end
        alias on_defs on_def

        private

        def implicit_begin?(body)
          return false unless body

          body.ensure_type? || clause_rescue?(body)
        end

        def clause_rescue?(node)
          node&.rescue_type? && !rescue_modifier?(node.resbody_branches.first)
        end

        def clause_keyword(body)
          clause = first_clause(body)
          clause.rescue_type? ? clause.resbody_branches.first.loc.keyword : clause.loc.keyword
        end

        def first_clause(body)
          return body unless body.ensure_type?

          inner = body.children.first
          clause_rescue?(inner) ? inner : body
        end

        def safe_to_correct?(node, body)
          own_body_lines?(node, body) && !multiline_literal?(body)
        end

        def own_body_lines?(node, body)
          node.loc.keyword.line < body.first_line && body.last_line < node.loc.end.line
        end

        def multiline_literal?(body)
          body.each_descendant(:any_str, :any_sym, :regexp).any? do |literal|
            literal.multiline? || (literal.respond_to?(:heredoc?) && literal.heredoc?)
          end
        end

        def wrap_in_begin(corrector, node, body)
          body_range = range_by_whole_lines(body.source_range)
          indent = indentation(node)
          corrector.replace(body_range, wrapped_body(body_range, indent))
        end

        def wrapped_body(body_range, indent)
          step = " " * configured_indentation_width
          shifted = body_range.source.each_line.map do |line|
            line.strip.empty? ? line : "#{step}#{line}"
          end.join
          "#{indent}begin\n#{shifted.chomp}\n#{indent}end"
        end
      end
    end
  end
end
