module ReadmeExamples
  ##
  # Reads behavioral claims out of YAML fence comments: a list item shaped
  # like `- Voucher # PaymentVoucher now passes` promises that merging the
  # suffix changes the named class's verdict, and the spec holds the README
  # to that promise.
  class ClaimScan
    CLAIM = /\A\s*-\s+(\w+)\s+#\s+(\w+) now (passes|flagged)/

    def initialize(fence)
      @fence = fence
    end

    def claims
      @fence.body.filter_map.with_index do |line, offset|
        match = line.match(CLAIM)
        build(match, @fence.line_number + offset) if match
      end
    end

    private

    def build(match, line_number)
      Claim.new(cop_name: section_cop, suffix: match[1], class_name: match[2],
                outcome: match[3].to_sym, line_number:)
    end

    def section_cop
      rule = SECTIONS[@fence.section]
      rule&.first
    end
  end
end
