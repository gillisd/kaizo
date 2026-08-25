module RuboCop
  module Cop
    module Kaizo
      # Requires the unit under test to be declared with `subject`, not `let`.
      # `subject` is RSpec's name for the object being specified; hiding it in a
      # `let` obscures which object the examples are about and forfeits
      # `is_expected`/one-liner syntax.
      #
      # A `let` (or `let!`) is flagged when the value it returns is confidently
      # an instance of the class under test: the block's final expression is a
      # `.new` call on `described_class`, on the constant named by an enclosing
      # `describe`/`context` (full or short name), or on a constant matching the
      # spec's file name (`pool_spec.rb` names `Pool`, `api_client_spec.rb`
      # names `APIClient`).
      #
      # A `let` that builds a second instance on purpose -- an `other` for an
      # equality spec, say -- is exempted through `AllowedMethods` or
      # `AllowedPatterns`, both matched against the `let` name.
      #
      # There is no autocorrection: renaming the helper every example refers to
      # is a change the spec's author should make deliberately.
      #
      # == Configuration
      #
      # [+AllowedMethods+] `let` names never flagged. Default: none.
      # [+AllowedPatterns+] Regexps matched against the `let` name; a match is
      #                     exempt. Default: none.
      # [+Include+] Files the cop runs on. Default: <tt>**/*_spec.rb</tt>.
      #
      #   Kaizo/SpecSubject:
      #     AllowedMethods:
      #       - other       # a second instance for equality specs
      #     AllowedPatterns:
      #       - '\Aother_'
      #
      # @example
      #   # bad
      #   RSpec.describe Session::Pool do
      #     let(:pool) { described_class.new }
      #   end
      #
      #   # good
      #   RSpec.describe Session::Pool do
      #     subject(:pool) { described_class.new }
      #   end
      #
      # @example AllowedMethods: ['other'] (default: [])
      #   # good - a deliberate second instance
      #   RSpec.describe Session::Pool do
      #     subject(:pool) { described_class.new }
      #
      #     let(:other) { described_class.new }
      #   end
      #
      class SpecSubject < Base
        include AllowedMethods
        include AllowedPattern

        MSG = "Declare the unit under test with `subject(:%<name>s)`, not `let`.".freeze

        # @!method let_declaration(node)
        def_node_matcher :let_declaration, <<~PATTERN
          (block (send nil? {:let :let!} (sym $_)) _ $_)
        PATTERN

        # @!method constructed_class(node)
        def_node_matcher :constructed_class, <<~PATTERN
          (send ${(send nil? :described_class) (const _ _)} :new ...)
        PATTERN

        # @!method described_constant(node)
        def_node_matcher :described_constant, <<~PATTERN
          (block (send {(const {nil? cbase} :RSpec) nil?} {:describe :context} $(const ...) ...) ...)
        PATTERN

        def on_block(node)
          name, body = let_declaration(node)
          return unless name
          return if allowed_method?(name) || matches_allowed_pattern?(name.to_s)
          return unless unit_under_test?(node, final_expression(body))

          add_offense(node.send_node.loc.selector, message: format(MSG, name:))
        end

        private

        def final_expression(body)
          body&.begin_type? ? body.children.last : body
        end

        def unit_under_test?(node, expression)
          receiver = expression && constructed_class(expression)
          return false unless receiver
          return true if receiver.send_type?

          described?(node, receiver)
        end

        def described?(node, const_node)
          described_constants(node).any? do |described|
            described.const_name == const_node.const_name ||
              described.short_name == const_node.short_name
          end || file_named_after?(const_node.short_name)
        end

        def described_constants(node)
          node.each_ancestor(:block).filter_map { |ancestor| described_constant(ancestor) }
        end

        def file_named_after?(short_name)
          base = processed_source.file_path&.[](%r{([^/]+)_spec\.rb\z}, 1)
          base && short_name.to_s.downcase == base.delete("_")
        end
      end
    end
  end
end
