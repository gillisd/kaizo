module RuboCop
  module Cop
    module Kaizo
      # Requires temporary files to be created with block-form `Tempfile.create`,
      # and flags `Tempfile.new`, `Tempfile.open`, and blockless `Tempfile.create`.
      #
      # Only the block form cleans up deterministically: the file is closed and
      # removed when the block returns, however it returns. A `Tempfile` built
      # with `.new` or `.open` is removed by a GC finalizer that runs at some
      # unpredictable point -- possibly never -- and blockless `Tempfile.create`
      # hands back a plain `File` that is never removed automatically at all.
      #
      # There is no autocorrection: moving the file's users into the block is a
      # restructuring, and the block's return value replaces the handle the old
      # code held onto.
      #
      # == Configuration
      #
      # No cop-specific options; the standard per-cop settings (+Enabled+,
      # +Severity+, +Include+/+Exclude+) apply.
      #
      # @example
      #   # bad
      #   file = Tempfile.new("report")
      #   file = Tempfile.open("report")
      #   file = Tempfile.create("report")
      #
      #   # good
      #   Tempfile.create("report") do |file|
      #     file.write(data)
      #   end
      #
      class TempfileCreate < Base
        MSG = "Use `Tempfile.create` with a block instead of `Tempfile.%<method>s`; " \
              "finalizer-based cleanup is unpredictable.".freeze
        BLOCKLESS_CREATE_MSG = "Pass a block to `Tempfile.create`; " \
                               "without one the file is never removed.".freeze

        RESTRICT_ON_SEND = %i[new open create].freeze

        # @!method tempfile_call?(node)
        def_node_matcher :tempfile_call?, <<~PATTERN
          (send (const {nil? cbase} :Tempfile) _ ...)
        PATTERN

        def on_send(node)
          return unless tempfile_call?(node)
          return if node.method?(:create) && block_given_to?(node)

          range = node.receiver.source_range.join(node.loc.selector)
          add_offense(range, message: message_for(node))
        end

        private

        def message_for(node)
          return BLOCKLESS_CREATE_MSG if node.method?(:create)

          format(MSG, method: node.method_name)
        end

        def block_given_to?(node)
          return true if node.last_argument&.block_pass_type?

          parent = node.parent
          parent&.any_block_type? && parent.send_node.equal?(node)
        end
      end
    end
  end
end
