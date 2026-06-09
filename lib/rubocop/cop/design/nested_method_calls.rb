# frozen_string_literal: true

module RuboCop
  module Cop
    module Design
      # Checks for method calls nested too deeply in argument positions.
      #
      # A call whose arguments are themselves the results of other calls --
      # `foo(SomeClass.new(another("bar").chain))` -- packs several steps into one
      # expression. Naming the intermediate results (or extracting a method) almost
      # always reads better and is easier to debug than peeling parentheses apart.
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
      #   # good - name the intermediate result
      #   parsed = parse(read(io))
      #   wrap(parsed)
      #
      #   # good - a single nested call is allowed
      #   puts compute(value)
      #
      class NestedMethodCalls < Base
        include AllowedMethods

        exclude_limit 'Max'

        MSG = 'Avoid nesting method calls in arguments; name an intermediate ' \
              'result instead. [%<depth>d/%<max>d]'

        # Node types whose children sit in argument position -- looked through to
        # reach nested calls (but never into a block body).
        TRANSPARENT_ARGUMENT_TYPES = %i[array hash begin pair splat kwsplat].freeze

        def on_send(node)
          return if nested_in_call_argument?(node)
          return if allowed_method?(node.method_name)

          max = cop_config['Max']
          depth = nesting_depth(node)
          return unless max && depth > max

          add_offense(node, message: format(MSG, depth: depth, max: max)) do
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

          does_work?(node)
        end

        # A call reads as a real nested step -- rather than a plain receiver
        # chain like `user.account.owner.name` -- only when it, or some call in
        # its receiver chain, actually takes arguments. Bare reader chains do
        # not count (that is the planned chaining cop's concern), while
        # `another("bar").chain` still does.
        def does_work?(node)
          return false unless node.call_type?
          return true if node.arguments.any?

          node.receiver ? does_work?(node.receiver) : false
        end

        # Whether `node` sits in an enclosing call's argument list (through
        # literals), so an outer call already accounts for it.
        def nested_in_call_argument?(node)
          parent = node.parent
          return false unless parent

          case parent.type
          when :send, :csend
            parent.arguments.include?(node)
          when :array, :hash, :pair, :begin, :splat, :kwsplat
            nested_in_call_argument?(parent)
          when :block, :numblock, :itblock
            # A call that carries a block is reached through its block node;
            # treat the block as transparent so the call it is attached to is
            # still recognised as nested inside any enclosing argument.
            parent.send_node.equal?(node) && nested_in_call_argument?(parent)
          else
            false
          end
        end
      end
    end
  end
end
