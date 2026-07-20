module RuboCop
  module Cop
    module Design
      # Prefer `Pathname` over `File` for the operations `Pathname` provides.
      #
      # Once a path is a `Pathname`, calling `pathname.read` or `pathname.exist?`
      # reads better than threading a string through `File.read(...)` or
      # `File.exist?(...)`. This cop flags calls to `File` class methods that have
      # a `Pathname` instance-method equivalent.
      #
      # By default the cop runs on `**/*.rb` and skips `exe/**/*` and `bin/**/*`
      # (executables often work with raw path strings); adjust with the standard
      # `Include`/`Exclude` options.
      #
      # There is no autocorrection: rewriting `File.read(path)` as
      # `Pathname(path).read` changes the receiver and is left to a human.
      #
      # @example
      #   # bad
      #   File.read(path)
      #   File.exist?(path)
      #   File.join(dir, name)
      #
      #   # good
      #   path.read
      #   path.exist?
      #   dir.join(name)
      #
      class PreferPathname < Base
        MSG = "Use `Pathname#%<method>s` instead of `File.%<method>s`.".freeze

        # `File` class methods that have a `Pathname` instance-method equivalent:
        # the intersection of File's class methods and Pathname's own instance
        # methods, excluding generic Object methods. Regenerate with:
        #   (Pathname.instance_methods(false) & File.methods).reject { |m| Object.respond_to?(m) }.sort
        RESTRICT_ON_SEND = %i[
          atime basename binread binwrite birthtime blockdev? chardev? chmod
          chown ctime delete directory? dirname empty? executable?
          executable_real? exist? expand_path extname file? fnmatch fnmatch?
          ftype grpowned? join lchmod lchown lstat lutime mtime open owned?
          path pipe? read readable? readable_real? readlines readlink
          realdirpath realpath rename setgid? setuid? size size? socket? split
          stat sticky? symlink? sysopen truncate unlink utime world_readable?
          world_writable? writable? writable_real? write zero?
        ].freeze

        # @!method file_call?(node)
        def_node_matcher :file_call?, <<~PATTERN
          (send (const {nil? cbase} :File) _ ...)
        PATTERN

        def on_send(node)
          return unless file_call?(node)

          range = node.receiver.source_range.join(node.loc.selector)
          add_offense(range, message: format(MSG, method: node.method_name))
        end
      end
    end
  end
end
