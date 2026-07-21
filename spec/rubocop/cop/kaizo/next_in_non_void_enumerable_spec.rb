RSpec.describe RuboCop::Cop::Kaizo::NextInNonVoidEnumerable, :config do
  context "with a bare `next` guard inside `map`" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        array.map do |i|
          next if collection.include?(i)
          ^^^^ Avoid `next` inside `map`; return a value from the block instead of using `next` for control flow.
        end
      RUBY
    end
  end

  context "with a `next <value>` inside `reduce`" do
    it "registers an offense (control-flow-as-value)" do
      expect_offense(<<~RUBY)
        array.reduce(0) do |sum, item|
          next sum if skip?(item)
          ^^^^ Avoid `next` inside `reduce`; return a value from the block instead of using `next` for control flow.

          sum + item
        end
      RUBY
    end
  end

  context "with `next` inside a numbered-parameter `select` block" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        array.select { next if _1.bad? }
                       ^^^^ Avoid `next` inside `select`; return a value from the block instead of using `next` for control flow.
      RUBY
    end
  end

  context "with `next` inside a predicate method (`any?`)" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        array.any? do |i|
          next true if special?(i)
          ^^^^ Avoid `next` inside `any?`; return a value from the block instead of using `next` for control flow.

          valid?(i)
        end
      RUBY
    end
  end

  context "with several `next` statements in one flagged block" do
    it "registers an offense for each" do
      expect_offense(<<~RUBY)
        array.filter_map do |i|
          next if a?(i)
          ^^^^ Avoid `next` inside `filter_map`; return a value from the block instead of using `next` for control flow.
          next 0 if b?(i)
          ^^^^ Avoid `next` inside `filter_map`; return a value from the block instead of using `next` for control flow.

          i
        end
      RUBY
    end
  end

  context "with `next` inside `each`" do
    it "does not register an offense (void iteration method)" do
      expect_no_offenses(<<~RUBY)
        array.each do |i|
          next if collection.include?(i)

          process(i)
        end
      RUBY
    end
  end

  context "with `next` inside `each_with_object`" do
    it "does not register an offense (block return value is ignored)" do
      expect_no_offenses(<<~RUBY)
        array.each_with_object([]) do |i, acc|
          next if skip?(i)

          acc << transform(i)
        end
      RUBY
    end
  end

  context "with `next` inside `each_slice`" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        array.each_slice(2) do |pair|
          next if pair.empty?

          handle(pair)
        end
      RUBY
    end
  end

  context "with a void `each` nested inside `map`" do
    it "attributes the inner `next` to `each` and does not flag `map`" do
      expect_no_offenses(<<~RUBY)
        array.map do |i|
          other.each do |j|
            next if j.bad?

            j.touch
          end
        end
      RUBY
    end
  end

  context "with a `map` nested inside `map`" do
    it "flags only the inner block that owns the `next`" do
      expect_offense(<<~RUBY)
        outer.map do |i|
          inner.map do |j|
            next if j.bad?
            ^^^^ Avoid `next` inside `map`; return a value from the block instead of using `next` for control flow.

            j * 2
          end
        end
      RUBY
    end
  end

  context "with `next` inside a `while` loop nested in `map`" do
    it "attributes the `next` to the loop and does not flag `map`" do
      expect_no_offenses(<<~RUBY)
        array.map do |i|
          while cond?
            next if done?
          end
          i
        end
      RUBY
    end
  end

  context "with `next` inside a non-Enumerable block (`loop`)" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        loop do
          next if wait?

          work
        end
      RUBY
    end
  end

  context "with a flagged method listed in AllowedMethods" do
    let(:cop_config) { { "AllowedMethods" => ["reduce"] } }

    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        array.reduce(0) do |sum, item|
          next sum if skip?(item)

          sum + item
        end
      RUBY
    end
  end

  context "with a flagged method matched by AllowedPatterns" do
    let(:cop_config) { { "AllowedPatterns" => ["\\Amap\\z"] } }

    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        array.map do |i|
          next if skip?(i)

          i
        end
      RUBY
    end
  end

  context "with a flagged block that contains no `next`" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        array.map { |i| i * 2 }
      RUBY
    end
  end
end
