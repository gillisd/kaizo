RSpec.describe RuboCop::Cop::Kaizo::PositionalArguments, :config do
  context "with `Max: 2`" do
    let(:cop_config) { { "Max" => 2 } }

    it "registers an offense for too many positional arguments" do
      expect_offense(<<~RUBY)
        def move(x, y, z)
            ^^^^ Method has too many positional arguments. [3/2]
        end
      RUBY
    end

    it "counts optional positional arguments" do
      expect_offense(<<~RUBY)
        def scale(x, y = 1, z = 2)
            ^^^^^ Method has too many positional arguments. [3/2]
        end
      RUBY
    end

    it "does not count keyword arguments" do
      expect_no_offenses(<<~RUBY)
        def configure(host, port:, timeout:, retries:)
        end
      RUBY
    end
  end

  context "with an operator method" do
    let(:cop_config) { { "Max" => 1 } }

    it "exempts element assignment (`[]=`)" do
      expect_no_offenses(<<~RUBY)
        def []=(key, value)
        end
      RUBY
    end

    it "exempts element reference with two indices (`[]`)" do
      expect_no_offenses(<<~RUBY)
        def [](row, column)
        end
      RUBY
    end

    it "exempts a singleton operator definition (`def self.[]=`)" do
      expect_no_offenses(<<~RUBY)
        def self.[]=(key, value)
        end
      RUBY
    end

    it "exempts a binary operator at `Max: 0`" do
      cop_config["Max"] = 0
      expect_no_offenses(<<~RUBY)
        def <=>(other)
        end
      RUBY
    end

    it "still registers an offense for a non-operator method" do
      expect_offense(<<~RUBY)
        def store(key, value)
            ^^^^^ Method has too many positional arguments. [2/1]
        end
      RUBY
    end

    it "exempts an operator defined with `define_method`" do
      expect_no_offenses(<<~RUBY)
        define_method(:[]=) { |key, value| nil }
      RUBY
    end

    it "exempts an operator defined with `define_singleton_method`" do
      expect_no_offenses(<<~RUBY)
        obj.define_singleton_method(:[]=) { |key, value| nil }
      RUBY
    end

    it "still registers an offense for a non-operator `define_method`" do
      expect_offense(<<~RUBY)
        define_method(:store) { |key, value| nil }
        ^^^^^^^^^^^^^ Method has too many positional arguments. [2/1]
      RUBY
    end

    it "still registers an offense for a dynamically named `define_method`" do
      expect_offense(<<~RUBY)
        define_method(name) { |key, value| nil }
        ^^^^^^^^^^^^^ Method has too many positional arguments. [2/1]
      RUBY
    end
  end
end
