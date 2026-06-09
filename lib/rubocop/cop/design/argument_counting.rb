module RuboCop
  module Cop
    module Design
      # Shared traversal and counting for the argument-arity cops.
      #
      # Walks method definitions written with `def`, `def self.`, `define_method`,
      # and `define_singleton_method`, and reports when the argument count
      # produced by the including cop exceeds the configured `Max`. Including cops
      # must define a private `arity(arguments)` method and a `KIND` constant. The
      # `initialize` of a `Struct.new`/`Data.define` block is exempt.
      module ArgumentCounting
        POSITIONAL_TYPES = %i[arg optarg].freeze
        KEYWORD_TYPES = %i[kwarg kwoptarg].freeze
        DEFINE_METHODS = %i[define_method define_singleton_method].freeze
        STRUCT_OR_DATA = { "Struct" => :new, "Data" => :define }.freeze
        MSG = "Method has too many %<kind>s. [%<count>d/%<max>d]".freeze

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
          max = cop_config["Max"]
          count = arity(node.arguments)
          return unless max && count > max

          message = format(MSG, kind: self.class::KIND, count: count, max: max)
          add_offense(offense_location(node), message: message) { self.max = count }
        end

        def offense_location(node)
          node.any_block_type? ? node.send_node.loc.selector : node.loc.name
        end

        def allowed_initialize?(node)
          node.method?(:initialize) && struct_or_data_definition?(enclosing_block(node))
        end

        # The block a method definition lives in, seen through the `begin` that
        # wraps the body when the block holds more than one statement.
        def enclosing_block(node)
          parent = node.parent
          parent&.begin_type? ? parent.parent : parent
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
