RSpec.describe RuboCop::Cop::Kaizo::NestedMethodCalls, :config do
  let(:cop_config) { { "Max" => 1, "AllowedMethods" => [] } }

  it "registers one offense for the canonical nested example" do
    expect_offense(<<~RUBY)
      foo(SomeClass.new(another("bar").chain))
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid nesting method calls in arguments; name the intermediate result to document what it is. [2/1]
    RUBY
  end

  it "registers an offense for two-deep argument nesting" do
    expect_offense(<<~RUBY)
      wrap(parse(read(io)))
      ^^^^^^^^^^^^^^^^^^^^^ Avoid nesting method calls in arguments; name the intermediate result to document what it is. [2/1]
    RUBY
  end

  it "descends through hash-literal arguments" do
    expect_offense(<<~RUBY)
      build(user: make(parse(input)))
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid nesting method calls in arguments; name the intermediate result to document what it is. [2/1]
    RUBY
  end

  it "allows a single nested call" do
    expect_no_offenses("puts compute(value)")
  end

  it "does not count a bare value argument" do
    expect_no_offenses("foo(bar)")
  end

  it "does not count a receiver chain argument (chaining is separate)" do
    expect_no_offenses("present(user.account.owner.name)")
  end

  it "does not count a receiver chain argument even at Max: 0" do
    cop_config["Max"] = 0
    expect_no_offenses("present(user.account.owner.name)")
  end

  it "does not count operator or index arguments" do
    expect_no_offenses(<<~RUBY)
      total(price + tax)
      fetch(list[index])
    RUBY
  end

  it "does not count a plain receiver chain" do
    expect_no_offenses("user.account.owner.name")
  end

  it "does not enter block bodies when measuring the outer call" do
    expect_no_offenses("render(items.map { |x| x.to_s })")
  end

  it "reports a block-bearing argument call only once" do
    expect_offense(<<~RUBY)
      foo(arr.reduce(seed(deep(x))) { })
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid nesting method calls in arguments; name the intermediate result to document what it is. [3/1]
    RUBY
  end

  it "respects Max" do
    cop_config["Max"] = 2
    expect_no_offenses("wrap(parse(read(io)))")
  end

  context "with AllowedMethods" do
    let(:cop_config) { { "Max" => 1, "AllowedMethods" => ["wrap"] } }

    it "does not flag an allowed outer method" do
      expect_no_offenses("wrap(parse(read(io)))")
    end
  end
end
