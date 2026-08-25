module ReadmeExamples
  ##
  # Verifies a console fence against reality: every offense line must exactly
  # match an offense the cops emit for the preceding bad example, the summary
  # count must agree, and every other line must be the command, a blank, a
  # source line from the example, or a caret marker -- so the terminal output
  # shown in the README is re-derived, never transcribed on faith.
  class ConsoleCheck
    OFFENSE = /\A\S+?:\d+:\d+: [A-Z]: \S+: .+\z/
    SUMMARY = /\A\d+ files? inspected, (\d+) offenses? detected\z/
    COMMAND = /\A\$ /
    CARETS = /\A\s*\^+\z/

    def initialize(fence, bad_snippets, offense_check)
      @fence = fence
      @bad_snippets = bad_snippets
      @offense_check = offense_check
    end

    def problems
      return ["no offense lines in #{locate}"] if shown_path.nil?

      [offense_problems, summary_problems, stray_problems].flatten.compact
    end

    private

    def locate
      "console fence (README.md:#{@fence.line_number})"
    end

    def shown_path
      first = @fence.body.grep(OFFENSE).first
      first&.slice(/\A[^:]+/)
    end

    def expected_lines
      @expected_lines ||= @bad_snippets.flat_map do |snippet|
        @offense_check.rendered_lines(snippet, shown_path)
      end
    end

    def offense_problems
      actual = @fence.body.grep(OFFENSE)
      return if actual == expected_lines

      ["#{locate} shows:\n#{actual.join("\n")}\nbut the cops emit:\n#{expected_lines.join("\n")}"]
    end

    def summary_problems
      counts = @fence.body.filter_map { |line| line[SUMMARY, 1] }
      return if counts == [expected_lines.size.to_s]

      ["#{locate} must end with a summary counting #{expected_lines.size} offenses"]
    end

    def stray_problems
      @fence.body.reject { |line| recognized?(line) }
                 .map { |line| "unrecognized line in #{locate}: #{line.inspect}" }
    end

    def recognized?(line)
      return true if line.strip.empty? || [OFFENSE, SUMMARY, COMMAND, CARETS].any? { |form| line.match?(form) }

      @bad_snippets.any? { |snippet| snippet.code.lines.map(&:chomp).include?(line) }
    end
  end
end
