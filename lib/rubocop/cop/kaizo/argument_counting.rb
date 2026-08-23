module RuboCop
  module Cop
    module Kaizo
      # Shared traversal and counting for the argument-arity cops.
      #
      # Walks method definitions written with `def`, `def self.`, `define_method`,
      # and `define_singleton_method`, and reports when the argument count
      # produced by the including cop exceeds the configured `Max`. Including cops
      # must define a private `arity(arguments)` method and a `KIND` constant.
      # Operator methods (`[]=`, `[]`, `<=>`, ...) and the `initialize` of a
      # `Struct.new`/`Data.define` block are exempt.
      module ArgumentCounting
        include AllowedMethods
        include AllowedPattern

        POSITIONAL_TYPES = %i[arg optarg].freeze
        KEYWORD_TYPES = %i[kwarg kwoptarg].freeze
        DEFINE_METHODS = %i[define_method define_singleton_method].freeze
        STRUCT_OR_DATA = { "Struct" => :new, "Data" => :define }.freeze

        # Ruby's operator method names, mirroring the list behind RuboCop's
        # `operator_method?` (private upstream, so it cannot be reused). Needed
        # only for the `define_method(:[]=)` form, where the name being defined is
        # a symbol argument rather than a `def` node we could ask directly.
        OPERATOR_METHOD_NAMES = [
          :!, :!=, :"!@", :!~, :%, :&, :*, :**, :+, :+@, :-, :-@, :/, :<, :<<, :<=,
          :<=>, :==, :===, :=~, :>, :>=, :>>, :[], :[]=, :^, :`, :|, :~, :"~@"
        ].freeze
        MSG = "Method has too many %<kind>s. [%<count>d/%<max>d]".freeze

        def on_def(node)
          return if exempt?(node)

          check_arity(node)
        end
        alias on_defs on_def

        def on_block(node)
          return unless DEFINE_METHODS.include?(node.method_name)
          return if exempt_defined_name?(node)

          check_arity(node)
        end
        alias on_numblock on_block
        alias on_itblock on_block

        private

        # A definition whose argument count is not a design choice. An operator
        # method's arity is fixed by Ruby's syntax -- `[]=` takes the indices plus
        # the assigned value, `<=>` takes its right-hand side -- so it cannot be
        # modeled away, and a `Struct`/`Data` `initialize` just mirrors the members
        # the value object was declared with.
        def exempt?(node)
          node.operator_method? || allowed_initialize?(node) || allowed_name?(node.method_name)
        end

        # The same exemptions for `define_method(:[]=)`, which names the method it
        # defines with a symbol (or string) argument. A computed name is still
        # checked -- we cannot know what it resolves to.
        def exempt_defined_name?(node)
          defined_name = node.send_node.first_argument
          return false unless defined_name&.type?(:sym, :str)

          name = defined_name.value.to_sym
          OPERATOR_METHOD_NAMES.include?(name) || allowed_name?(name)
        end

        def allowed_name?(name)
          allowed_method?(name) || matches_allowed_pattern?(name.to_s)
        end

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

          message = format(MSG, kind: self.class::KIND, count:, max:)
          add_offense(offense_location(node), message:) { self.max = count }
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
