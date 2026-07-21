require "rubocop"

require_relative "kaizo/version"
require_relative "kaizo/plugin"

require_relative "rubocop/cop/kaizo_cops"

# Kaizo ships a strict, punishing set of RuboCop cops aimed at AI-agent-authored
# code: they bound argument counts, flag agent-noun class names, flag calls
# nested too deeply in other calls' arguments, and treat comments and loose
# descriptions in specs as structure that wants to be expressed properly.
module Kaizo
  # Base error class for kaizo.
  class Error < StandardError; end
end
