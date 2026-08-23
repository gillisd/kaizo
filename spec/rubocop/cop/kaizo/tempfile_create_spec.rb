RSpec.describe RuboCop::Cop::Kaizo::TempfileCreate, :config do
  it "registers an offense for `Tempfile.new`" do
    expect_offense(<<~RUBY)
      file = Tempfile.new("report")
             ^^^^^^^^^^^^ Use `Tempfile.create` with a block instead of `Tempfile.new`; finalizer-based cleanup is unpredictable.
    RUBY
  end

  it "registers an offense for a fully qualified `::Tempfile.new`" do
    expect_offense(<<~RUBY)
      file = ::Tempfile.new("report")
             ^^^^^^^^^^^^^^ Use `Tempfile.create` with a block instead of `Tempfile.new`; finalizer-based cleanup is unpredictable.
    RUBY
  end

  it "registers an offense for `Tempfile.open` with a block" do
    expect_offense(<<~RUBY)
      Tempfile.open("report") do |file|
      ^^^^^^^^^^^^^ Use `Tempfile.create` with a block instead of `Tempfile.open`; finalizer-based cleanup is unpredictable.
        file.write(data)
      end
    RUBY
  end

  it "registers an offense for `Tempfile.open` without a block" do
    expect_offense(<<~RUBY)
      file = Tempfile.open("report")
             ^^^^^^^^^^^^^ Use `Tempfile.create` with a block instead of `Tempfile.open`; finalizer-based cleanup is unpredictable.
    RUBY
  end

  it "registers an offense for `Tempfile.create` without a block" do
    expect_offense(<<~RUBY)
      file = Tempfile.create("report")
             ^^^^^^^^^^^^^^^ Pass a block to `Tempfile.create`; without one the file is never removed.
    RUBY
  end

  it "does not register an offense for `Tempfile.create` with a block" do
    expect_no_offenses(<<~RUBY)
      Tempfile.create("report") do |file|
        file.write(data)
      end
    RUBY
  end

  it "does not register an offense for `Tempfile.create` with a numbered-parameter block" do
    expect_no_offenses(<<~RUBY)
      Tempfile.create("report") { _1.write(data) }
    RUBY
  end

  it "does not register an offense for `Tempfile.create` with a block-pass argument" do
    expect_no_offenses(<<~RUBY)
      Tempfile.create("report", &writer)
    RUBY
  end

  it "does not register an offense for `new` on a namespaced Tempfile constant" do
    expect_no_offenses(<<~RUBY)
      file = Acme::Tempfile.new("report")
    RUBY
  end

  it "does not register an offense for unrelated Tempfile class methods" do
    expect_no_offenses(<<~RUBY)
      Tempfile.instance_method(:path)
    RUBY
  end
end
