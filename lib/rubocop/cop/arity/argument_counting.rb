# frozen_string_literal: true

module RuboCop
  module Cop
    module Arity
      # Shared traversal and counting for the argument-arity cops.
      #
      # Walks method definitions written with `def`, `def self.`, `define_method`,
      # and `define_singleton_method`, and checks the configured `Min`/`Max`
      # bounds against a count produced by the including cop. Including cops must
      # define a private `arity(arguments)` method and a `KIND` constant. `Min`
      # is ignored when zero, and the `initialize` of a `Struct.new`/`Data.define`
      # block is exempt.
      module ArgumentCounting
        POSITIONAL_TYPES = %i[arg optarg].freeze
        KEYWORD_TYPES = %i[kwarg kwoptarg].freeze
        DEFINE_METHODS = %i[define_method define_singleton_method].freeze
        STRUCT_OR_DATA = { 'Struct' => :new, 'Data' => :define }.freeze

        # The configured bounds for one kind of argument. Given a count, returns
        # the offense message when it is out of bounds, or `nil` when acceptable.
        # Plain object rather than a `Struct` so the `max`/`min` readers do not
        # shadow `Enumerable#max`/`#min` (Lint/StructNewOverride).
        class Bound
          def initialize(kind:, max:, min:)
            @kind = kind
            @max = max
            @min = min
          end

          def too_many(count)
            return unless @max && count > @max

            format('Method has too many %<kind>s. [%<count>d/%<max>d]', kind: @kind, count: count, max: @max)
          end

          def too_few(count)
            return unless @min&.positive? && count < @min

            format('Method has too few %<kind>s. [%<count>d/%<min>d]', kind: @kind, count: count, min: @min)
          end
        end

        def on_def(node)
          return if allowed_initialize?(node)

          check_arity(node)
        end
        alias on_defs on_def

        def on_block(node)
          check_arity(node) if DEFINE_METHODS.include?(node.method_name)
        end
        alias on_numblock on_block
        alias on_itblock on_block

        private

        def positional_arity(arguments)
          arguments.count { |argument| POSITIONAL_TYPES.include?(argument.type) }
        end

        def keyword_arity(arguments)
          arguments.count { |argument| KEYWORD_TYPES.include?(argument.type) }
        end

        def check_arity(node)
          bound = Bound.new(kind: self.class::KIND, max: cop_config['Max'], min: cop_config['Min'])
          count = arity(node.arguments)
          location = offense_location(node)

          if (message = bound.too_many(count))
            add_offense(location, message: message) { self.max = count }
          elsif (message = bound.too_few(count))
            add_offense(location, message: message)
          end
        end

        def offense_location(node)
          node.any_block_type? ? node.send_node.loc.selector : node.loc.name
        end

        def allowed_initialize?(node)
          node.method?(:initialize) && struct_or_data_definition?(node.parent)
        end

        def struct_or_data_definition?(node)
          return false unless node&.block_type?

          receiver = node.receiver
          receiver&.const_type? && node.method?(STRUCT_OR_DATA[receiver.const_name])
        end
      end
    end
  end
end
