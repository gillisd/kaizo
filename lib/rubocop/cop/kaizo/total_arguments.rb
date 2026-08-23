module RuboCop
  module Cop
    module Kaizo
      # Checks that a method does not declare too many arguments in total
      # (positional plus keyword).
      #
      # The goal is to apply pressure toward good domain modeling: a long
      # argument list is often a sign of primitive obsession, and bundling the
      # related values into an object usually expresses the intent better.
      #
      # `*rest`, `**keyword-rest`, and `&block` arguments are not counted. The
      # `initialize` of a `Struct.new`/`Data.define` block is exempt, since those
      # parameters mirror the value object's attributes.
      #
      # == Configuration
      #
      # [+Max+] Most arguments -- positional plus keyword -- a method may
      #         declare. Default: +2+.
      # [+AllowedMethods+] Method names exempt from the limit. Default: none.
      # [+AllowedPatterns+] Regexps matched against the method name; a match is
      #                     exempt. Default: none.
      #
      #   Kaizo/TotalArguments:
      #     Max: 3
      #     AllowedMethods:
      #       - initialize
      #
      # @example Max: 3
      #   # bad
      #   def calculate_volume(width, length, height, shape_type)
      #   end
      #
      #   # good
      #   def calculate_volume(shape)
      #   end
      #
      class TotalArguments < Base
        include ArgumentCounting

        exclude_limit "Max"

        KIND = "arguments".freeze

        private

        def arity(arguments)
          positional_arity(arguments) + keyword_arity(arguments)
        end
      end
    end
  end
end
