# frozen_string_literal: true

require_relative 'lib/rubocop/arity/version'

Gem::Specification.new do |spec|
  spec.name = 'rubocop-arity'
  spec.version = RuboCop::Arity::VERSION
  spec.authors = ['Flipmine']
  spec.email = ['david@flipmine.com']

  spec.summary = 'RuboCop cops that limit how many arguments a method may declare.'
  spec.description = 'Configurable RuboCop cops that bound the number of positional, keyword, ' \
                     'and total arguments a method declares, to apply pressure toward good ' \
                     'domain modeling and away from primitive obsession.'
  spec.homepage = 'https://github.com/flipmine/rubocop-arity'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['default_lint_roller_plugin'] = 'RuboCop::Arity::Plugin'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'config/**/*.yml', 'CHANGELOG.md', 'LICENSE.txt', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'lint_roller', '~> 1.1'
  spec.add_dependency 'rubocop', '>= 1.72.2'
end
