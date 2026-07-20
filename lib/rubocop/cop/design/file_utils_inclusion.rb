module RuboCop
  module Cop
    module Design
      # Requires `FileUtils` to be mixed in with `include` (or `extend`) once it
      # is used more than once in a class or module, rather than qualifying every
      # call with the `FileUtils.` receiver.
      #
      # Repeating the `FileUtils.` receiver is noise; mixing the module in once
      # names the capability and lets the body call `mkdir_p`, `cp`, and friends
      # directly. Use `include` for instance-level use and `extend` for
      # class/singleton-level use. A single qualified call is left alone, and a
      # class or module that already mixes `FileUtils` in is not flagged.
      #
      # The class or module is reported once. Nested classes and modules are
      # counted on their own -- one call in an outer class and one in a nested
      # class do not add up -- and a `FileUtils` call in the superclass
      # expression does not count toward the class body.
      #
      # There is no autocorrection: whether to `include` or `extend`, and where
      # the mixin belongs, is a judgment call for a human.
      #
      # @example
      #   # bad - the `FileUtils.` receiver is repeated
      #   class Backup
      #     def run
      #       FileUtils.mkdir_p(dir)
      #       FileUtils.cp(src, dir)
      #     end
      #   end
      #
      #   # good - mix it in once, then call unqualified
      #   class Backup
      #     include FileUtils
      #
      #     def run
      #       mkdir_p(dir)
      #       cp(src, dir)
      #     end
      #   end
      #
      class FileUtilsInclusion < Base
        MSG = "`FileUtils` is used %<count>d times in this %<scope>s; " \
              "`include`/`extend` FileUtils and call its methods unqualified.".freeze

        # @!method file_utils_call?(node)
        def_node_matcher :file_utils_call?, <<~PATTERN
          (send (const {nil? cbase} :FileUtils) ...)
        PATTERN

        # @!method file_utils_mixin?(node)
        def_node_matcher :file_utils_mixin?, <<~PATTERN
          (send nil? {:include :extend} (const {nil? cbase} :FileUtils) ...)
        PATTERN

        def on_class(node)
          check(node, "class")
        end

        def on_module(node)
          check(node, "module")
        end

        private

        def check(node, scope)
          return if own_sends(node) { |send| file_utils_mixin?(send) }.any?

          count = own_sends(node) { |send| file_utils_call?(send) }.size
          return if count < 2

          add_offense(node.loc.name, message: format(MSG, count: count, scope: scope))
        end

        # Sends in `namespace`'s own body that match the block -- not its
        # superclass expression, and not a nested class or module (those own
        # their sends and are checked on their own).
        def own_sends(namespace)
          body = namespace.body
          return [] unless body

          [body, *body.each_descendant].select do |send_node|
            send_node.send_type? && yield(send_node) && owning_namespace(send_node).equal?(namespace)
          end
        end

        def owning_namespace(node)
          node.each_ancestor(:class, :module).first
        end
      end
    end
  end
end
