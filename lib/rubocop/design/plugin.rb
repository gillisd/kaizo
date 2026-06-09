require "lint_roller"

module RuboCop
  module Design
    # A plugin that integrates rubocop-design with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: "rubocop-design",
          version: VERSION,
          homepage: "https://github.com/flipmine/rubocop-design",
          description: "Cops that limit the number of arguments a method may declare.",
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join("../../../config/default.yml"),
        )
      end
    end
  end
end
