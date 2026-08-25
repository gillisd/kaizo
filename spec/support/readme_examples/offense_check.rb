module ReadmeExamples
  ##
  # Runs kaizo's cops over a snippet exactly as RuboCop would, returning the
  # offending cop names. Claims run against the shipped config with the
  # claimed suffix merged in, mirroring an `inherit_mode: merge` override.
  class OffenseCheck
    def initialize(config)
      @config = config
    end

    def names(snippet)
      run(kaizo_cops, @config, parse(snippet.code, snippet.path)).map(&:cop_name)
    end

    def claim_names(claim)
      cop_class = kaizo_cops.find { |cop| cop.cop_name == claim.cop_name }
      code = "class #{claim.class_name}\nend\n"
      run([cop_class], claim_config(claim), parse(code, (ROOT + APP_PATH).to_s)).map(&:cop_name)
    end

    def rendered_lines(snippet, shown_path)
      offenses = run(kaizo_cops, @config, parse(snippet.code, snippet.path))
      offenses.map do |offense|
        "#{shown_path}:#{offense.line}:#{offense.real_column}: " \
          "#{offense.severity.code}: #{offense.cop_name}: #{offense.message}"
      end
    end

    private

    def run(cop_classes, config, source)
      registry = RuboCop::Cop::Registry.new(cop_classes)
      team = RuboCop::Cop::Team.mobilize(registry, config)
      team.investigate(source).offenses
    end

    def parse(code, path)
      source = RuboCop::ProcessedSource.new(code, @config.target_ruby_version, path)
      raise ArgumentError, "invalid ruby in #{path}:\n#{code}" unless source.valid_syntax?

      source
    end

    def kaizo_cops
      RuboCop::Cop::Registry.global.cops.select { |cop| cop.department == :Kaizo }
    end

    def claim_config(claim)
      key = claim.outcome == :passes ? "AllowedSuffixes" : "ForbiddenSuffixes"
      base = @config[claim.cop_name]
      merged = base.merge(key => Array(base[key]) | [claim.suffix])
      RuboCop::Config.new({ claim.cop_name => merged }, "README.md")
    end
  end
end
