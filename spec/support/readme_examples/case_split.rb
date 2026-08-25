module ReadmeExamples
  ##
  # Splits marked ruby fences into verifiable snippets. A marker comment
  # opens each case -- `# bad` or `# good`, optionally naming the cop it
  # demonstrates when it is not the section's own, and optionally naming the
  # path the code lives at (`# good -- spec/support/builders.rb: ...`) when
  # path-scoped behavior is the point. Unmarked code in a mapped section is
  # reported as a violation, so no example escapes verification; the marker
  # line itself is stripped from the code before the cops run.
  class CaseSplit
    MARKER = /\A#\s*(bad|good)\b/
    COP_NAME = %r{Kaizo/\w+}
    PATH_HINT = %r{[\w/]+\.rb}

    def initialize(fences)
      @snippets = []
      @violations = []
      fences.select { |fence| fence.lang == "ruby" }.each { |fence| split(fence) }
    end

    attr_reader :snippets

    def violations = @violations.uniq

    private

    def split(fence)
      rule = SECTIONS[fence.section]
      return orphan_check(fence) unless rule

      @groups = []
      fence.body.each_with_index { |line, offset| place(fence, line, offset) }
      @groups.each { |group| build(fence, rule, group) }
    end

    def place(fence, line, offset)
      if line.match?(MARKER)
        @groups << [line, [], fence.line_number + offset]
      elsif @groups.empty?
        stray(fence, line)
      else
        @groups.last[1] << line
      end
    end

    def build(fence, rule, group)
      marker, lines, number = group
      code = lines.join("\n").strip
      return @violations << "empty case in #{locate(fence)}" if code.empty?

      expectation = marker[MARKER, 1].to_sym
      cop_name = marker[COP_NAME] || rule.first
      snippet = Snippet.new(section: fence.section, expectation:, cop_name:,
                            code: "#{code}\n", path: case_path(marker, rule),
                            line_number: number)
      @snippets << snippet
    end

    def case_path(marker, rule)
      (ROOT + (marker[PATH_HINT] || rule.last)).to_s
    end

    def stray(fence, line)
      return if line.strip.empty?

      @violations << "unmarked code before the first marker in #{locate(fence)}"
    end

    def orphan_check(fence)
      return unless fence.body.any? { |line| line.match?(MARKER) }

      @violations << "marked fence in unmapped #{locate(fence)}"
    end

    def locate(fence)
      "section #{fence.section.inspect} (README.md:#{fence.line_number})"
    end
  end
end
