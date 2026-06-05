# frozen_string_literal: true

module RuboCop
  module Cop
    module Arity
      # Checks that a method does not declare too many positional arguments.
      #
      # Positional arguments are unnamed and order-dependent, which makes a long
      # list of them especially prone to primitive obsession. Required (`arg`)
      # and optional (`optarg`) parameters are counted; `*rest` and `&block` are
      # not.
      #
      # @example Max: 2
      #   # bad
      #   def move(x, y, z)
      #   end
      #
      #   # good
      #   def move(point)
      #   end
      #
      class PositionalArguments < Base
        include ArgumentCounting

        exclude_limit 'Max'

        KIND = 'positional arguments'

        private

        def arity(arguments)
          positional_arity(arguments)
        end
      end
    end
  end
end
