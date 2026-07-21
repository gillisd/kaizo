RSpec.describe RuboCop::Cop::Kaizo::PreferPathname, :config do
  context "with a `File` method that Pathname also provides" do
    it "registers an offense for `File.read`" do
      expect_offense(<<~RUBY)
        File.read("x")
        ^^^^^^^^^ Use `Pathname#read` instead of `File.read`.
      RUBY
    end

    it "registers an offense for `File.exist?`" do
      expect_offense(<<~RUBY)
        File.exist?(path)
        ^^^^^^^^^^^ Use `Pathname#exist?` instead of `File.exist?`.
      RUBY
    end

    it "registers an offense for `File.join`" do
      expect_offense(<<~RUBY)
        File.join(a, b)
        ^^^^^^^^^ Use `Pathname#join` instead of `File.join`.
      RUBY
    end

    it "registers an offense for `File.expand_path`" do
      expect_offense(<<~RUBY)
        File.expand_path("x")
        ^^^^^^^^^^^^^^^^ Use `Pathname#expand_path` instead of `File.expand_path`.
      RUBY
    end
  end

  context "with a fully-qualified `::File`" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        ::File.read(path)
        ^^^^^^^^^^^ Use `Pathname#read` instead of `File.read`.
      RUBY
    end
  end

  context "with a `File` method that Pathname does not provide" do
    it "does not register an offense for `File.new`" do
      expect_no_offenses(<<~RUBY)
        File.new(path)
      RUBY
    end

    it "does not register an offense for `File.path` (Pathname#path is protected)" do
      expect_no_offenses(<<~RUBY)
        File.path(obj)
      RUBY
    end
  end

  context "with a matching method on a different receiver" do
    it "does not register an offense for a lowercase receiver" do
      expect_no_offenses(<<~RUBY)
        file.read(path)
      RUBY
    end

    it "does not register an offense for `FileTest`" do
      expect_no_offenses(<<~RUBY)
        FileTest.exist?(path)
      RUBY
    end

    it "does not register an offense for a receiverless call" do
      expect_no_offenses(<<~RUBY)
        read(path)
      RUBY
    end
  end
end
