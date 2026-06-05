# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module Arity
    # A plugin that integrates rubocop-arity with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: 'rubocop-arity',
          version: VERSION,
          homepage: 'https://github.com/flipmine/rubocop-arity',
          description: 'Cops that limit the number of arguments a method may declare.'
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join('../../../config/default.yml')
        )
      end
    end
  end
end
