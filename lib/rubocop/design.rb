require_relative "design/version"

module RuboCop
  # RuboCop::Design ships cops that apply pressure toward good object and domain
  # design: they bound argument counts, flag agent-noun class names, and flag
  # calls nested too deeply in other calls' arguments.
  module Design
    # Base error class for rubocop-design.
    class Error < StandardError; end
  end
end
