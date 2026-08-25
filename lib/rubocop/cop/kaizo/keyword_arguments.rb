module RuboCop
  module Cop
    module Kaizo
      # Checks that a method does not declare too many keyword arguments.
      #
      # Keyword arguments are self-documenting, but a long list of them is still
      # a sign that the related values want to be modeled as an object. Required
      # (`kwarg`) and optional (`kwoptarg`) parameters are counted; `**rest` is
      # not.
      #
      # == Configuration
      #
      # [+Max+] Most keyword arguments a method may declare. Default: +1+.
      # [+AllowedMethods+] Method names exempt from the limit. Default: none.
      # [+AllowedPatterns+] Regexps matched against the method name; a match is
      #                     exempt. Default: none.
      # [+Exclude+] Paths the cop skips. Default: <tt>**/spec/**/*</tt> and
      #             <tt>**/test/**/*</tt> -- wide keyword interfaces are the
      #             testing idiom (FactoryBot-style builders), so keyword
      #             counts are not policed there. Set it to <tt>[]</tt> to
      #             police tests too.
      #
      #   Kaizo/KeywordArguments:
      #     Max: 2
      #     AllowedMethods:
      #       - initialize
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
      # @example AllowedMethods: ['initialize'] (default: [])
      #   # good - exempt by name
      #   def initialize(host:, port:, ssl: true)
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
