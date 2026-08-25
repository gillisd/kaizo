module ReadmeExamples
  ##
  # Checks a YAML fence against the shipped config: every cop key must name a
  # registered cop, and every kaizo option key must exist in the shipped
  # defaults -- the guard against documenting renamed or imaginary options.
  class ConfigAudit
    STANDARD_KEYS = %w[
      inherit_mode Enabled Severity AutoCorrect Max
      Include Exclude AllowedMethods AllowedPatterns
    ].freeze

    def initialize(fence, config)
      @fence = fence
      @config = config
    end

    def unknown_cops
      cop_keys.reject { |name| registered_cop_names.include?(name) }
    end

    def unknown_params
      cop_keys.grep(%r{\AKaizo/}).flat_map { |name| bad_params(name) }
    end

    private

    def parsed_yaml
      @parsed_yaml ||= YAML.safe_load(@fence.body.join("\n")) || {}
    end

    def cop_keys
      parsed_yaml.keys.grep(%r{/})
    end

    def registered_cop_names
      @registered_cop_names ||= RuboCop::Cop::Registry.global.names
    end

    def bad_params(name)
      params = parsed_yaml.fetch(name).keys - STANDARD_KEYS
      (params - @config[name].keys).map { |param| "#{name}: #{param}" }
    end
  end
end
