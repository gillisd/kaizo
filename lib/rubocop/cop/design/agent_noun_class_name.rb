module RuboCop
  module Cop
    module Design
      # Checks for classes named as agent nouns ("doers") rather than the domain
      # concepts they model. A class whose name ends in `er` or `or` (`Manager`,
      # `Processor`, `Handler`) -- or in any configured `ForbiddenSuffixes` such
      # as `Service` -- usually signals procedural behavior that wants a clearer
      # domain name or a different home.
      #
      # Names ending in an `AllowedSuffixes` entry are exempt; the match is by
      # suffix, so `Controller` clears both `Controller` and `UsersController`.
      # `ForbiddenSuffixes` always flags, even when also matched by
      # `AllowedSuffixes` -- which is how you drop a default exemption.
      #
      # `class` definitions and `Struct.new`/`Data.define`/`Class.new` constant
      # assignments are both checked. There is no autocorrection: renaming a
      # class is a design decision.
      #
      # @example
      #   # bad
      #   class PaymentProcessor
      #   end
      #
      #   # good
      #   class Payment
      #   end
      #
      # @example
      #   # good - ends in an allowed suffix
      #   class UsersController
      #   end
      #
      class AgentNounClassName < Base
        MSG = "Avoid the doer-style class name `%<name>s`. " \
              "Prefer a name for the concept it models over the action it performs.".freeze
        AGENT_NOUN = /(?:er|or)\z/i

        # @!method class_builder_assignment(node)
        def_node_matcher :class_builder_assignment, <<~PATTERN
          (casgn _ $_ {
            (send (const _ {:Struct :Data :Class}) {:new :define} ...)
            (block (send (const _ {:Struct :Data :Class}) {:new :define} ...) ...)
          })
        PATTERN

        def on_class(node)
          check_name(node.identifier.short_name.to_s, node.loc.name)
        end

        def on_casgn(node)
          return unless (name = class_builder_assignment(node))

          check_name(name.to_s, node.loc.name)
        end

        private

        def check_name(name, location)
          return unless offending?(name)

          add_offense(location, message: format(MSG, name: name))
        end

        def offending?(name)
          return true if ends_with_any?(name, "ForbiddenSuffixes")

          AGENT_NOUN.match?(name) && !ends_with_any?(name, "AllowedSuffixes")
        end

        def ends_with_any?(name, config_key)
          Array(cop_config[config_key]).any? { |suffix| name.end_with?(suffix) }
        end
      end
    end
  end
end
