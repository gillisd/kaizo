RSpec.describe RuboCop::Cop::Kaizo::PluralCollectionName, :config do
  let(:cop_config) do
    { "AllowedMethods" => [], "IrregularPlurals" => ["people", "children"] }
  end

  it "registers an offense for a singular method returning an array literal" do
    expect_offense(<<~RUBY)
      def user
          ^^^^ Name a method that returns a collection in the plural. `user` returns an array.
        [first, second]
      end
    RUBY
  end

  it "registers an offense for an explicit array return" do
    expect_offense(<<~RUBY)
      def item
          ^^^^ Name a method that returns a collection in the plural. `item` returns an array.
        return [] if empty?

        [one, two]
      end
    RUBY
  end

  it "registers an offense for a trailing `map`" do
    expect_offense(<<~RUBY)
      def name
          ^^^^ Name a method that returns a collection in the plural. `name` returns an array.
        rows.map { |row| row.to_s }
      end
    RUBY
  end

  it "registers an offense on a singleton definition" do
    expect_offense(<<~RUBY)
      def self.record
               ^^^^^^ Name a method that returns a collection in the plural. `record` returns an array.
        [a, b]
      end
    RUBY
  end

  it "does not register an offense for an already-plural name" do
    expect_no_offenses(<<~RUBY)
      def users
        [first, second]
      end
    RUBY
  end

  it "does not register an offense for a configured irregular plural" do
    expect_no_offenses(<<~RUBY)
      def people
        [first, second]
      end
    RUBY
  end

  it "does not register an offense for a predicate method" do
    expect_no_offenses(<<~RUBY)
      def valid?
        [a, b]
      end
    RUBY
  end

  it "does not register an offense for a writer method" do
    expect_no_offenses(<<~RUBY)
      def name=(value)
        [value]
      end
    RUBY
  end

  it "does not register an offense for an operator method" do
    expect_no_offenses(<<~RUBY)
      def [](index)
        [index]
      end
    RUBY
  end

  it "does not register an offense for `initialize`" do
    expect_no_offenses(<<~RUBY)
      def initialize
        @rows = [a, b]
      end
    RUBY
  end

  it "does not register an offense when the return type is not obviously an array" do
    expect_no_offenses(<<~RUBY)
      def user
        find_the_user
      end
    RUBY
  end

  it "does not register an offense for `select`, whose result follows its receiver" do
    expect_no_offenses(<<~RUBY)
      def entry
        rows.select { |row| row.live? }
      end
    RUBY
  end

  it "does not register an offense when only one branch returns an array" do
    expect_no_offenses(<<~RUBY)
      def user
        return nil if missing?

        [one, two]
      end
    RUBY
  end

  it "does not register an offense for an empty method" do
    expect_no_offenses(<<~RUBY)
      def user
      end
    RUBY
  end

  context "with AllowedMethods" do
    let(:cop_config) do
      { "AllowedMethods" => ["user"], "IrregularPlurals" => [] }
    end

    it "does not flag an allowed method" do
      expect_no_offenses(<<~RUBY)
        def user
          [first, second]
        end
      RUBY
    end
  end
end
