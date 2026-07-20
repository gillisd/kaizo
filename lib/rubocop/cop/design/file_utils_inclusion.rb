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
      # class/singleton-level use. A single qualified call is left alone.
      #
      # Nested classes and modules are counted on their own, so one call in an
      # outer class and one in a nested class do not add up.
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

        def on_class(node)
          check(node, "class")
        end

        def on_module(node)
          check(node, "module")
        end

        private

        def check(node, scope)
          calls = file_utils_calls(node)
          return if calls.size < 2

          message = format(MSG, count: calls.size, scope: scope)
          calls.each { |call| add_offense(call.receiver, message: message) }
        end

        # `FileUtils.` calls whose nearest enclosing namespace is `namespace`
        # itself -- calls inside a nested class or module belong to that nested
        # scope, which gets checked on its own.
        def file_utils_calls(namespace)
          namespace.each_descendant(:send).select do |node|
            file_utils_call?(node) && owning_namespace(node).equal?(namespace)
          end
        end

        def owning_namespace(node)
          node.each_ancestor(:class, :module).first
        end
      end
    end
  end
end
