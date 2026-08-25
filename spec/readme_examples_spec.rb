RSpec.describe "README examples" do
  let(:config) { RuboCop::ConfigLoader.load_file("config/default.yml") }
  let(:check) { ReadmeExamples::OffenseCheck.new(config) }

  it "maps every documented section to a real README heading" do
    expect(ReadmeExamples.stale_sections).to be_empty
  end

  it "marks every example so none escape verification" do
    expect(ReadmeExamples.violations).to be_empty
  end

  it "shows a verified bad example for every cop" do
    covered = ReadmeExamples.snippets.select { |snippet| snippet.expectation == :bad }.map(&:cop_name)
    expect(ReadmeExamples.cop_names - covered).to be_empty
  end

  it "shows a verified good example for every cop" do
    covered = ReadmeExamples.snippets.select { |snippet| snippet.expectation == :good }.map(&:cop_name)
    expect(ReadmeExamples.cop_names - covered).to be_empty
  end

  ReadmeExamples.snippets.each do |snippet|
    describe "the #{snippet.section} example at README.md:#{snippet.line_number}" do
      if snippet.expectation == :bad
        it "is flagged by #{snippet.cop_name}" do
          expect(check.names(snippet)).to include(snippet.cop_name)
        end
      else
        it "passes every kaizo cop" do
          expect(check.names(snippet)).to be_empty
        end
      end
    end
  end

  ReadmeExamples.yaml_fences.each do |fence|
    describe "the #{fence.section} config at README.md:#{fence.line_number}" do
      let(:audit) { ReadmeExamples::ConfigAudit.new(fence, config) }

      it "names only registered cops" do
        expect(audit.unknown_cops).to be_empty
      end

      it "uses only shipped option keys" do
        expect(audit.unknown_params).to be_empty
      end
    end
  end

  ReadmeExamples.claims.each do |claim|
    it "keeps the promise that #{claim.class_name} is now #{claim.outcome} (README.md:#{claim.line_number})" do
      names = check.claim_names(claim)
      expected = claim.outcome == :flagged ? include(claim.cop_name) : be_empty
      expect(names).to expected
    end
  end
end
