require "lint_roller"

module Kaizo
  # A plugin that integrates kaizo with RuboCop's plugin system.
  class Plugin < LintRoller::Plugin
    def about
      LintRoller::About.new(
        name: "kaizo",
        version: VERSION,
        homepage: "https://github.com/flipmine/kaizo",
        description: "A strict, punishing set of design cops for AI-agent-authored Ruby.",
      )
    end

    def supported?(context)
      context.engine == :rubocop
    end

    def rules(_context)
      LintRoller::Rules.new(
        type: :path,
        config_format: :rubocop,
        value: Pathname.new(__dir__).join("../../config/default.yml"),
      )
    end
  end
end
