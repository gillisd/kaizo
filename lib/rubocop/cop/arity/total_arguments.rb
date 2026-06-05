# frozen_string_literal: true

module RuboCop
  module Cop
    module Arity
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

        exclude_limit 'Max'

        KIND = 'arguments'

        private

        def arity(arguments)
          positional_arity(arguments) + keyword_arity(arguments)
        end
      end
    end
  end
end
