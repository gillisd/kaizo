module RuboCop
  module Cop
    module Kaizo
      # Flags `next` used inside the block of a value-returning `Enumerable`
      # method such as `map`, `select`, or `reduce`, whose block value is
      # significant. In those methods `next` doubles as a way to produce the
      # block's value through control flow, which this cop discourages in
      # favor of an expression that produces the value directly.
      #
      # "Void" iteration methods, whose block return value is ignored (`each`,
      # `each_with_index`, `each_slice`, `each_with_object`, `reverse_each`,
      # and so on), are intentionally *not* flagged: there `next` merely skips
      # to the next iteration. The same goes for non-`Enumerable` looping
      # constructs such as `loop`, `Integer#times`, and `while`. Additional
      # methods can be exempted through `AllowedMethods` / `AllowedPatterns`.
      #
      # A `next` that binds to a nested block or loop is attributed to that
      # inner scope, so an inner `each { next }` does not flag an outer `map`.
      #
      # There is no autocorrection: the right fix depends on intent -- a guard
      # clause might become a ternary, a `select`/`reject`, a `filter_map`, or a
      # restructured block.
      #
      # @example
      #   # bad
      #   array.map do |item|
      #     next if skip?(item)
      #
      #     transform(item)
      #   end
      #
      #   # bad - `next <value>` is still control-flow-as-value
      #   array.reduce(0) do |sum, item|
      #     next sum if skip?(item)
      #
      #     sum + item
      #   end
      #
      #   # good - a void iteration method skips with `next`
      #   array.each do |item|
      #     next if skip?(item)
      #
      #     process(item)
      #   end
      #
      #   # good - express the intent with a value-returning form
      #   array.filter_map do |item|
      #     transform(item) unless skip?(item)
      #   end
      #
      # @example AllowedMethods: ['reduce'] (default: [])
      #   # good - `reduce` exempted by configuration
      #   array.reduce(0) do |sum, item|
      #     next sum if skip?(item)
      #
      #     sum + item
      #   end
      #
      class NextInNonVoidEnumerable < Base
        include AllowedMethods
        include AllowedPattern

        MSG = "Avoid `next` inside `%<method>s`; return a value from the " \
              "block instead of using `next` for control flow.".freeze

        # `Enumerable` methods whose block return value determines the result.
        # Void iteration methods (`each`, `each_with_object`, `reverse_each`,
        # `cycle`, ...) are deliberately absent, which is why `next` is allowed
        # in them.
        FLAGGED_METHODS = %i[
          all? any? none? one?
          chunk_while
          collect collect_concat
          count
          detect
          drop_while
          filter filter_map find find_all find_index
          flat_map
          grep grep_v
          group_by
          inject
          map
          max_by min_by minmax_by
          partition
          reduce reject
          select
          slice_when
          sort_by
          sum
          take_while
        ].freeze

        # Node types that introduce a new `next` binding. A `next` found below
        # one of these belongs to that inner scope, not the enumerable block
        # under inspection, so descent stops here.
        SCOPE_BOUNDARIES = %i[
          block numblock itblock while until while_post until_post for
        ].freeze

        def on_block(node)
          call = node.children.first
          return unless call.respond_to?(:method_name)

          method = call.method_name
          return unless FLAGGED_METHODS.include?(method)
          return if allowed_method?(method) || matches_allowed_pattern?(method.to_s)

          flag_block_local_nexts(node, method)
        end
        alias on_numblock on_block
        alias on_itblock on_block

        private

        def flag_block_local_nexts(block_node, method)
          message = format(MSG, method:)

          block_node.each_child_node do |child|
            each_block_local_next(child) do |next_node|
              add_offense(next_node.loc.keyword, message:)
            end
          end
        end

        def each_block_local_next(node, &)
          yield node if node.next_type?
          return if SCOPE_BOUNDARIES.include?(node.type)

          node.each_child_node { |child| each_block_local_next(child, &) }
        end
      end
    end
  end
end
