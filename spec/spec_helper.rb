require "rubocop-design"
require "rubocop/rspec/support"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.raise_errors_for_deprecations!
  config.raise_on_warning = true
  config.fail_if_no_examples = true

  config.example_status_persistence_file_path = ".rspec_status"
  config.order = :random
  Kernel.srand config.seed
end
