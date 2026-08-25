module RuboCop
  module Cop
    module Kaizo
      # Checks that a method does not declare too many positional arguments.
      #
      # Positional arguments are unnamed and order-dependent, which makes a long
      # list of them especially prone to primitive obsession. Required (`arg`)
      # and optional (`optarg`) parameters are counted; `*rest` and `&block` are
      # not.
      #
      # Unlike the keyword-counting cops, this one runs everywhere, spec and
      # test trees included: positional arguments communicate nothing unless
      # they are solo, in test code as much as anywhere else.
      #
      # == Configuration
      #
      # [+Max+] Most positional arguments a method may declare. Default: +1+.
      # [+AllowedMethods+] Method names exempt from the limit. Default: none.
      # [+AllowedPatterns+] Regexps matched against the method name; a match is
      #                     exempt. Default: none.
      #
      #   Kaizo/PositionalArguments:
      #     Max: 0        # force every argument to be a keyword
      #     AllowedMethods:
      #       - initialize
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

        exclude_limit "Max"

        KIND = "positional arguments".freeze

        private

        def arity(arguments)
          positional_arity(arguments)
        end
      end
    end
  end
end
