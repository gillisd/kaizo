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
end
