module RuboCop
  module Cop
    module Kaizo
      # Checks for method calls nested too deeply in argument positions.
      #
      # A call whose arguments are themselves the results of other calls --
      # `foo(SomeClass.new(another("bar").chain))` -- packs several steps into one
      # expression. Giving the intermediate results descriptive names (or extracting
      # a method) almost always reads better and is easier to debug than peeling
      # parentheses apart. The point is not the assignment but the name: it should
      # say what the value is, so the step documents itself.
      #
      # Only nesting through *argument* positions is counted; a receiver chain such
      # as `user.account.owner.name` is a separate concern. Operator methods
      # (`a + b`, `arr[i]`) never count, and calls to `AllowedMethods` are exempt.
      # Depth is measured from each outermost call and reported once. There is no
      # autocorrection: choosing the intermediate name is a design decision.
      #
      # @example Max: 1 (default)
      #   # bad
      #   foo(SomeClass.new(another("bar").chain))
      #
      #   # bad
      #   wrap(parse(read(io)))
      #
      #   # good - a name that documents what the value is
      #   parsed_config = parse(read(io))
      #   wrap(parsed_config)
      #
      #   # good - a single nested call is allowed
      #   puts compute(value)
      #
      class NestedMethodCalls < Base
        include AllowedMethods

        exclude_limit "Max"

        MSG = "Avoid nesting method calls in arguments; name an intermediate " \
              "result instead. [%<depth>d/%<max>d]".freeze

        # Node types whose children sit in argument position -- looked through to
        # reach nested calls (but never into a block body).
        TRANSPARENT_ARGUMENT_TYPES = %i[array hash begin pair splat kwsplat].freeze

        def on_send(node)
          return if nested_in_call_argument?(node)
          return if allowed_method?(node.method_name)

          max = cop_config["Max"]
          depth = nesting_depth(node)
          return unless max && depth > max

          add_offense(node, message: format(MSG, depth:, max:)) do
            self.max = depth
          end
        end
        alias on_csend on_send

        private

        # Longest chain of significant calls reachable through this call's
        # argument positions. Receivers and block bodies are not traversed.
        def nesting_depth(call)
          nested = argument_calls(call)
          return 0 if nested.empty?

          1 + nested.map { |inner| nesting_depth(inner) }.max
        end

        def argument_calls(call)
          call.arguments.flat_map { |argument| calls_in(argument) }
        end

        # Significant calls at the top of an argument expression, seen through
        # array/hash literals but never into a block body.
        def calls_in(node)
          return significant_calls(node) if node.call_type?
          return significant_calls(node.send_node) if node.any_block_type?
          return [] unless TRANSPARENT_ARGUMENT_TYPES.include?(node.type)

          node.children.flat_map { |child| calls_in(child) }
        end

        # `node` wrapped in an array when it is a significant call, else empty.
        def significant_calls(node)
          significant_call?(node) ? [node] : []
        end

        def significant_call?(node)
          return false unless node.call_type?
          return false if node.operator_method?
          return false if allowed_method?(node.method_name)

          chain_takes_arguments?(node)
        end

        # A call reads as a real nested step -- rather than a plain receiver
        # chain like `user.account.owner.name` -- only when it, or some call in
        # its receiver chain, actually takes arguments. Bare reader chains do
        # not count (that is the planned chaining cop's concern), while
        # `another("bar").chain` still does.
        def chain_takes_arguments?(node)
          return false unless node.call_type?
          return true if node.arguments.any?

          node.receiver ? chain_takes_arguments?(node.receiver) : false
        end

        # Whether `node` sits in an enclosing call's argument list (through
        # literal containers or the call a block is attached to), so an outer
        # call already accounts for it.
        def nested_in_call_argument?(node)
          parent = node.parent
          return false unless parent
          return parent.arguments.include?(node) if parent.call_type?
          return nested_in_call_argument?(parent) if reached_through?(parent, node)

          false
        end

        # A parent an outer call sees through to reach `node`: any literal
        # container, or a block -- but only via the call it is attached to,
        # never its body.
        def reached_through?(parent, node)
          return true if TRANSPARENT_ARGUMENT_TYPES.include?(parent.type)

          parent.any_block_type? && parent.send_node.equal?(node)
        end
      end
    end
  end
end
