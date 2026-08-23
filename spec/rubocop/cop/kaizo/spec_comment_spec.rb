RSpec.describe RuboCop::Cop::Kaizo::SpecComment, :config do
  it "registers an offense for a standalone comment" do
    expect_offense(<<~RUBY)
      # set up an admin user
      ^^^^^^^^^^^^^^^^^^^^^^ Avoid comments in specs. Express the intent as a `context`/`it` description or a clearer example instead.
      it { is_expected.to be_valid }
    RUBY
  end

  it "registers an offense for a trailing (inline) comment" do
    expect_offense(<<~RUBY)
      subject { described_class.new } # the thing under test
                                      ^^^^^^^^^^^^^^^^^^^^^^ Avoid comments in specs. Express the intent as a `context`/`it` description or a clearer example instead.
    RUBY
  end

  it "registers an offense for a block comment" do
    expect_offense(<<~RUBY)
      =begin
      ^^^^^^ Avoid comments in specs. Express the intent as a `context`/`it` description or a clearer example instead.
      explanatory prose
      =end
    RUBY
  end

  it "does not flag a frozen_string_literal magic comment" do
    expect_no_offenses(<<~RUBY)
      # frozen_string_literal: true
      it { is_expected.to be_valid }
    RUBY
  end

  it "does not flag an encoding magic comment" do
    expect_no_offenses(<<~RUBY)
      # encoding: utf-8
    RUBY
  end

  it "flags a magic-comment-shaped comment below the leading position" do
    expect_offense(<<~RUBY)
      it { is_expected.to be_valid }
      # frozen_string_literal: true
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comments in specs. Express the intent as a `context`/`it` description or a clearer example instead.
    RUBY
  end

  it "does not flag rubocop directives" do
    expect_no_offenses(<<~RUBY)
      # rubocop:disable Layout/LineLength
      x = 1
      # rubocop:enable Layout/LineLength
    RUBY
  end

  it "does not flag a shebang" do
    expect_no_offenses(<<~RUBY)
      #!/usr/bin/env ruby
    RUBY
  end

  it "does not register an offense for a spec with no comments" do
    expect_no_offenses(<<~RUBY)
      it 'permits an admin to see everything' do
        expect(policy).to permit(admin)
      end
    RUBY
  end

  context "when AllowedPatterns permits a marker" do
    let(:cop_config) { { "AllowedPatterns" => ['\A#\s*noqa\b'] } }

    it "does not flag a comment matching an allowed pattern" do
      expect_no_offenses(<<~RUBY)
        # noqa: keep this
      RUBY
    end
  end

  context "with the shipped default configuration" do
    subject(:shipped_cop) { described_class.new(shipped_config) }

    let(:shipped_config) { RuboCop::ConfigLoader.load_file("config/default.yml") }

    it "inspects spec files" do
      model_spec = project_path("spec/models/user_spec.rb")
      expect(shipped_cop.relevant_file?(model_spec)).to be(true)
    end

    it "skips spec files under spec/helpers" do
      helper_spec = project_path("spec/helpers/api_spec.rb")
      expect(shipped_cop.relevant_file?(helper_spec)).to be(false)
    end

    it "skips spec files under spec/support" do
      support_spec = project_path("spec/support/matchers_spec.rb")
      expect(shipped_cop.relevant_file?(support_spec)).to be(false)
    end

    it "skips files that are not specs" do
      helper_file = project_path("spec/helpers/api_helper.rb")
      expect(shipped_cop.relevant_file?(helper_file)).to be(false)
    end

    it "keeps the helper exclusion when only Include is broadened" do
      cop = described_class.new(config_overriding("Include" => ["**/spec/**/*"]))
      helper_file = project_path("spec/helpers/api_helper.rb")

      expect(cop.relevant_file?(helper_file)).to be(false)
    end

    it "inspects support code with a broadened Include" do
      cop = described_class.new(config_overriding("Include" => ["**/spec/**/*"]))
      helper_file = project_path("spec/spec_helper.rb")

      expect(cop.relevant_file?(helper_file)).to be(true)
    end

    it "inspects helper specs again when the exclusion is overridden" do
      cop = described_class.new(config_overriding("Exclude" => []))
      helper_spec = project_path("spec/helpers/api_spec.rb")

      expect(cop.relevant_file?(helper_spec)).to be(true)
    end

    def project_path(relative)
      "#{Dir.pwd}/#{relative}"
    end

    def config_overriding(overrides)
      merged = shipped_config["Kaizo/SpecComment"].merge(overrides)
      RuboCop::Config.new({ "Kaizo/SpecComment" => merged }, ".rubocop.yml")
    end
  end
end
