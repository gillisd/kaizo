# frozen_string_literal: true

module RuboCop
  module Cop
    module Arity
      # Shared traversal and counting for the argument-arity cops.
      #
      # Walks method definitions written with `def`, `def self.`, `define_method`,
      # and `define_singleton_method`, and checks the configured `Min`/`Max`
      # bounds against a count produced by the including cop. Including cops must
      # define a private `arity(arguments)` method and a `KIND` constant (used in
      # the offense message). `Min` is ignored when zero, and the `initialize` of
      # a `Struct.new`/`Data.define` block is exempt.
      module ArgumentCounting
        POSITIONAL_TYPES = %i[arg optarg].freeze
        KEYWORD_TYPES = %i[kwarg kwoptarg].freeze
        DEFINE_METHODS = %i[define_method define_singleton_method].freeze
        STRUCT_OR_DATA = { 'Struct' => :new, 'Data' => :define }.freeze
        TOO_MANY = 'Method has too many %<kind>s. [%<count>d/%<limit>d]'
        TOO_FEW = 'Method has too few %<kind>s. [%<count>d/%<limit>d]'

        def on_def(node)
          return if allowed_initialize?(node)

          check_arity(node.loc.name, node.arguments)
        end
        alias on_defs on_def

        def on_block(node)
          return unless DEFINE_METHODS.include?(node.method_name)

          check_arity(node.send_node.loc.selector, node.arguments)
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

        def check_arity(location, arguments)
          count = arity(arguments)

          if too_many?(count)
            add_offense(location, message: arity_message(TOO_MANY, count, cop_config['Max'])) { self.max = count }
          elsif too_few?(count)
            add_offense(location, message: arity_message(TOO_FEW, count, cop_config['Min']))
          end
        end

        def too_many?(count)
          (max = cop_config['Max']) && count > max
        end

        def too_few?(count)
          (min = cop_config['Min']) && min.positive? && count < min
        end

        def arity_message(template, count, limit)
          format(template, kind: self.class::KIND, count: count, limit: limit)
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
