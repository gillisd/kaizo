require_relative "lib/kaizo/version"

Gem::Specification.new do |spec|
  spec.name = "kaizo"
  spec.version = Kaizo::VERSION
  spec.authors = ["Flipmine"]
  spec.email = ["david@flipmine.com"]

  spec.summary = "A strict, punishing set of RuboCop design cops for AI-agent-authored Ruby."
  spec.description = "RuboCop cops that hold AI-agent-authored Ruby to a demanding design bar: " \
                     "they bound positional, keyword, and total argument counts, flag agent-noun " \
                     "class names, flag calls nested too deeply in arguments, and keep spec " \
                     "comments and descriptions as structure -- applying steady pressure toward " \
                     "good domain modeling and away from primitive obsession."
  spec.homepage = "https://github.com/flipmine/kaizo"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["default_lint_roller_plugin"] = "Kaizo::Plugin"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "config/**/*.yml", "CHANGELOG.md", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "lint_roller", "~> 1.1"
  spec.add_dependency "rubocop", ">= 1.72.2"
end
