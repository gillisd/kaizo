module RuboCop
  module Cop
    module Design
      # Checks that a method does not declare too many keyword arguments.
      #
      # Keyword arguments are self-documenting, but a long list of them is still
      # a sign that the related values want to be modeled as an object. Required
      # (`kwarg`) and optional (`kwoptarg`) parameters are counted; `**rest` is
      # not.
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

        exclude_limit "Max"

        KIND = "keyword arguments".freeze

        private

        def arity(arguments)
          keyword_arity(arguments)
        end
      end
    end
  end
end
