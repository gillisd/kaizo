# frozen_string_literal: true

module RuboCop
  module Cop
    module Arity
      # Checks that a method does not declare too many keyword arguments.
      #
      # Keyword arguments are self-documenting, but a long list of them is still
      # a sign that the related values want to be modeled as an object. Required
      # (`kwarg`) and optional (`kwoptarg`) parameters are counted; `**rest` is
      # not. When `Min` is greater than zero, methods with too few keyword
      # arguments are also reported.
      #
      # @example Max: 2
      #   # bad
      #   def calculate_volume(width:, length:, height:)
      #   end
      #
      #   # good
      #   def calculate_volume(shape)
      #   end
      #
      class KeywordArguments < Base
        include ArgumentCounting

        exclude_limit 'Max'

        KIND = 'keyword arguments'

        private

        def arity(arguments)
          keyword_arity(arguments)
        end
      end
    end
  end
end
