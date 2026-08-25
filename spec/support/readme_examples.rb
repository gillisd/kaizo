require "yaml"

##
# Parses README.md into machine-verifiable pieces: bad/good code snippets,
# YAML config fences, and behavioral claims embedded in YAML comments. The
# readme_examples_spec runs every piece against the shipped config, so the
# README cannot drift from what the cops actually do.
module ReadmeExamples
  ROOT = Pathname(__dir__).parent.parent.freeze

  APP_PATH = "app/models/example.rb".freeze
  SPEC_PATH = "spec/models/example_spec.rb".freeze

  # Maps each README heading to the cop its bad examples demonstrate (a
  # marker comment can override per case) and the filename cops see, which
  # activates path-scoped cops for spec sections.
  SECTIONS = {
    "Kaizo" => ["Kaizo/PositionalArguments", APP_PATH],
    "Argument counts" => ["Kaizo/TotalArguments", APP_PATH],
    "Class naming" => ["Kaizo/AgentNounClassName", APP_PATH],
    "Nested method calls" => ["Kaizo/NestedMethodCalls", APP_PATH],
    "Comments in specs" => ["Kaizo/SpecComment", SPEC_PATH],
    "Spec description prose" => ["Kaizo/SpecDescriptionProse", SPEC_PATH],
    "Spec subject" => ["Kaizo/SpecSubject", "spec/session/pool_spec.rb"],
    "Including FileUtils" => ["Kaizo/FileUtilsInclusion", APP_PATH],
    "Prefer Pathname" => ["Kaizo/PreferPathname", APP_PATH],
    "Temp files" => ["Kaizo/TempfileCreate", APP_PATH],
    "Explicit begin" => ["Kaizo/ExplicitBegin", APP_PATH],
    "Next in value-returning blocks" => ["Kaizo/NextInNonVoidEnumerable", APP_PATH],
    "Plural names for collections" => ["Kaizo/PluralCollectionName", APP_PATH],
  }.freeze

  Fence = Data.define(:section, :lang, :body, :line_number).freeze
  Snippet = Data.define(:section, :expectation, :cop_name, :code, :path, :line_number).freeze
  Claim = Data.define(:cop_name, :suffix, :class_name, :outcome, :line_number).freeze

  module_function

  def snippets = case_split.snippets

  def violations = case_split.violations

  def yaml_fences = scan.fences.select { |fence| fence.lang == "yaml" }

  def claims
    yaml_fences.flat_map { |fence| ClaimScan.new(fence).claims }
  end

  def stale_sections = SECTIONS.keys - scan.headings

  def console_pairs
    console_fences.map { |fence| [fence, preceding_bad_snippets(fence)] }
  end

  def console_fences = scan.fences.select { |fence| fence.lang == "console" }

  def preceding_bad_snippets(console)
    source = ruby_fences_before(console).max_by(&:line_number)
    return [] unless source

    snippets.select do |snippet|
      snippet.expectation == :bad && snippet.section == console.section &&
        snippet.line_number >= source.line_number && snippet.line_number < console.line_number
    end
  end

  def ruby_fences_before(console)
    scan.fences.select do |fence|
      fence.lang == "ruby" && fence.section == console.section &&
        fence.line_number < console.line_number
    end
  end

  def cop_names
    RuboCop::Cop::Registry.global.names.grep(%r{\AKaizo/}).sort
  end

  def scan
    @scan ||= Scan.new(ROOT.join("README.md").read)
  end

  def case_split
    @case_split ||= CaseSplit.new(scan.fences)
  end
end

require_relative "readme_examples/scan"
require_relative "readme_examples/case_split"
require_relative "readme_examples/claim_scan"
require_relative "readme_examples/offense_check"
require_relative "readme_examples/config_audit"
require_relative "readme_examples/console_check"
