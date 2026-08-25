RSpec.describe RuboCop::Cop::Kaizo::KeywordArguments, :config do
  context "with `Max: 2`" do
    let(:cop_config) { { "Max" => 2 } }

    it "registers an offense for too many keyword arguments" do
      expect_offense(<<~RUBY)
        def calculate_volume(width:, length:, height:)
            ^^^^^^^^^^^^^^^^ Method has too many keyword arguments. [3/2]
        end
      RUBY
    end

    it "counts optional keyword arguments" do
      expect_offense(<<~RUBY)
        def connect(host:, port: 80, ssl: true)
            ^^^^^^^ Method has too many keyword arguments. [3/2]
        end
      RUBY
    end

    it "does not count positional arguments" do
      expect_no_offenses(<<~RUBY)
        def build(a, b, c, name:)
        end
      RUBY
    end

    it "checks `define_method` blocks" do
      expect_offense(<<~RUBY)
        define_method(:render) { |format:, layout:, locals:| nil }
        ^^^^^^^^^^^^^ Method has too many keyword arguments. [3/2]
      RUBY
    end
  end

  context "with `AllowedMethods`" do
    let(:cop_config) { { "Max" => 1, "AllowedMethods" => ["initialize"] } }

    it "exempts a listed instance method" do
      expect_no_offenses(<<~RUBY)
        def initialize(host:, port:, ssl: true)
        end
      RUBY
    end

    it "exempts a listed method defined with `define_method`" do
      expect_no_offenses(<<~RUBY)
        define_method(:initialize) { |host:, port:| nil }
      RUBY
    end

    it "still registers an offense for an unlisted method" do
      expect_offense(<<~RUBY)
        def connect(host:, port:)
            ^^^^^^^ Method has too many keyword arguments. [2/1]
        end
      RUBY
    end
  end

  context "with `AllowedPatterns`" do
    let(:cop_config) { { "Max" => 1, "AllowedPatterns" => ['\Abuild_'] } }

    it "exempts a matching method" do
      expect_no_offenses(<<~RUBY)
        def build_session(user:, scope:, ttl:)
        end
      RUBY
    end

    it "still registers an offense for a non-matching method" do
      expect_offense(<<~RUBY)
        def connect(host:, port:)
            ^^^^^^^ Method has too many keyword arguments. [2/1]
        end
      RUBY
    end
  end

  context "with the shipped default configuration" do
    subject(:shipped_cop) { described_class.new(shipped_config) }

    let(:shipped_config) { RuboCop::ConfigLoader.load_file("config/default.yml") }

    it "skips spec trees, where wide keyword builders are the idiom" do
      builder = project_path("spec/support/builders.rb")
      expect(shipped_cop.relevant_file?(builder)).to be(false)
    end

    it "skips test trees" do
      builder = project_path("test/support/builders.rb")
      expect(shipped_cop.relevant_file?(builder)).to be(false)
    end

    it "inspects application code" do
      model = project_path("app/models/order.rb")
      expect(shipped_cop.relevant_file?(model)).to be(true)
    end

    def project_path(relative)
      "#{Dir.pwd}/#{relative}"
    end
  end
end
