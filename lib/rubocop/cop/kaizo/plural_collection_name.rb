module RuboCop
  module Cop
    module Kaizo
      # Checks that a method returning a collection is named in the plural. A
      # singular name on a method handing back an array (`def user` returning
      # `[first, second]`) misdescribes what the caller gets; the plural does the
      # documenting for free.
      #
      # Ruby has no return types, so "returns an array" is a heuristic, and this
      # cop deliberately errs toward silence. A method is only flagged when
      # *every* value it can return is unambiguously an array: an array literal,
      # or a call to a method that returns an `Array` whatever its receiver
      # (`ArrayMethods`, e.g. `map`, `to_a`, `sort`). One branch returning `nil`
      # is enough to leave the method alone. Methods like `select` and `reject`
      # are absent by design -- on a `Hash` they hand back a `Hash`.
      #
      # A name counts as plural when it ends in `s` or appears in
      # `IrregularPlurals`. Predicate (`?`), writer (`=`), and operator methods
      # are exempt, as is `initialize`, and `AllowedMethods` exempts names
      # outright. There is no autocorrection: renaming a method is a design
      # decision, and only its author knows the right plural.
      #
      # @example
      #   # bad
      #   def user
      #     [first_match, second_match]
      #   end
      #
      #   # good
      #   def users
      #     [first_match, second_match]
      #   end
      #
      # @example
      #   # good - not confidently an array, so not flagged
      #   def user
      #     return nil if missing?
      #
      #     [first_match, second_match]
      #   end
      #
      class PluralCollectionName < Base
        include AllowedMethods

        MSG = "Name a method that returns a collection in the plural. " \
              "`%<name>s` returns an array.".freeze

        # Methods whose result is an `Array` regardless of the receiver. Kept
        # deliberately short: anything whose return type follows its receiver
        # (`select` on a `Hash`) would turn this cop into a false-positive mill.
        ARRAY_METHODS = %i[
          map flat_map collect collect_concat to_a entries sort sort_by zip
        ].freeze

        def on_def(node)
          return if exempt?(node)
          return unless returns_array?(node.body)

          add_offense(node.loc.name, message: format(MSG, name: node.method_name))
        end
        alias on_defs on_def

        private

        def exempt?(node)
          return true if node.predicate_method? || node.assignment_method?
          return true if node.operator_method? || node.method?(:initialize)

          plural?(node.method_name.to_s) || allowed_method?(node.method_name)
        end

        def plural?(name)
          name.end_with?("s") || irregular_plurals.include?(name)
        end

        def irregular_plurals
          Array(cop_config["IrregularPlurals"])
        end

        # Every value the method can hand back must be an array before it is
        # worth flagging, so that a single `return nil` keeps the cop quiet.
        def returns_array?(body)
          return false unless body

          results = [final_expression(body), *explicit_returns(body)]
          results.all? { |result| array_result?(result) }
        end

        def final_expression(body)
          body.begin_type? ? body.children.last : body
        end

        # The value of each `return`, with a bare `return` contributing `nil` --
        # which is exactly what should stop the method being flagged.
        def explicit_returns(body)
          body.each_descendant(:return).map { |node| node.children.first }
        end

        # A block-bearing call (`rows.map { ... }`) is a block node wrapping the
        # send, so the method name lives one level down.
        def array_result?(node)
          return false unless node
          return true if node.array_type?

          call = node.any_block_type? ? node.send_node : node
          call.call_type? && ARRAY_METHODS.include?(call.method_name)
        end
      end
    end
  end
end
