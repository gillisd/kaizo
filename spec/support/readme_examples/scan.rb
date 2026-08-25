module ReadmeExamples
  ##
  # Extracts fenced code blocks from markdown, tagging each with the nearest
  # `#`/`##` heading above it so fences can be mapped to the cop they
  # document; `###` subsections stay part of their parent section.
  class Scan
    HEADING = /\A##?\s+(.+?)\s*\z/
    OPENING = /\A```(\w*)\s*\z/

    attr_reader :fences, :headings

    def initialize(markdown)
      @fences = []
      @headings = []
      @section = nil
      @open = nil
      markdown.each_line.with_index(1) { |line, number| consume(line.chomp, number) }
    end

    private

    def consume(line, number)
      return accumulate(line) if @open
      return note_heading(line) if line.match?(HEADING)

      open_fence(line, number) if line.match?(OPENING)
    end

    def accumulate(line)
      return @open[:body] << line unless line.start_with?("```")

      @fences << Fence.new(**@open)
      @open = nil
    end

    def note_heading(line)
      heading = line[HEADING, 1]
      @headings << heading
      @section = heading
    end

    def open_fence(line, number)
      @open = { section: @section, lang: line[OPENING, 1], body: [], line_number: number + 1 }
    end
  end
end
