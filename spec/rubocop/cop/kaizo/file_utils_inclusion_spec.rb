RSpec.describe RuboCop::Cop::Kaizo::FileUtilsInclusion, :config do
  context "with two `FileUtils` calls in a class" do
    it "registers a single offense on the class" do
      expect_offense(<<~RUBY)
        class Backup
              ^^^^^^ `FileUtils` is used 2 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
          def run
            FileUtils.mkdir_p(dir)
            FileUtils.cp(src, dir)
          end
        end
      RUBY
    end
  end

  context "with two `FileUtils` calls in a module" do
    it "registers a single offense on the module" do
      expect_offense(<<~RUBY)
        module Helpers
               ^^^^^^^ `FileUtils` is used 2 times in this module; `include`/`extend` FileUtils and call its methods unqualified.
          def clean
            FileUtils.rm_rf(tmp)
          end

          def seed
            FileUtils.touch(flag)
          end
        end
      RUBY
    end
  end

  context "with `FileUtils` used in both an instance and a singleton method" do
    it "counts them together and reports the class once" do
      expect_offense(<<~RUBY)
        class Store
              ^^^^^ `FileUtils` is used 2 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
          def self.reset
            FileUtils.rm_rf(root)
          end

          def write
            FileUtils.mkdir_p(root)
          end
        end
      RUBY
    end
  end

  context "with three `FileUtils` calls" do
    it "reports the count as three" do
      expect_offense(<<~RUBY)
        class Backup
              ^^^^^^ `FileUtils` is used 3 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
          def run
            FileUtils.mkdir_p(dir)
            FileUtils.cp(a, dir)
            FileUtils.chmod(0o755, dir)
          end
        end
      RUBY
    end
  end

  context "with a fully-qualified `::FileUtils`" do
    it "counts it and reports the class once" do
      expect_offense(<<~RUBY)
        class Backup
              ^^^^^^ `FileUtils` is used 2 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
          def run
            ::FileUtils.mkdir_p(dir)
            ::FileUtils.cp(src, dir)
          end
        end
      RUBY
    end
  end

  context "with a single `FileUtils` call in a class" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class Backup
          def run
            FileUtils.mkdir_p(dir)
          end
        end
      RUBY
    end
  end

  context "when the class already includes FileUtils" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class Backup
          include FileUtils

          def run
            FileUtils.mkdir_p(dir)
            FileUtils.cp(src, dir)
          end
        end
      RUBY
    end
  end

  context "when the class already extends FileUtils" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class Backup
          extend FileUtils

          def self.run
            FileUtils.mkdir_p(dir)
            FileUtils.cp(src, dir)
          end
        end
      RUBY
    end
  end

  context "with a `FileUtils` call in the superclass expression" do
    it "does not count the superclass call toward the class body" do
      expect_no_offenses(<<~RUBY)
        class Backup < FileUtils.const_get(:Base)
          def run
            FileUtils.mkdir_p(dir)
          end
        end
      RUBY
    end
  end

  context "with one `FileUtils` call in the outer class and one in a nested class" do
    it "counts each namespace on its own and flags neither" do
      expect_no_offenses(<<~RUBY)
        class Outer
          def run
            FileUtils.mkdir_p(dir)
          end

          class Inner
            def clean
              FileUtils.rm_rf(dir)
            end
          end
        end
      RUBY
    end
  end

  context "with two `FileUtils` calls inside a nested class" do
    it "reports only the nested class that owns them" do
      expect_offense(<<~RUBY)
        class Outer
          class Inner
                ^^^^^ `FileUtils` is used 2 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
            def run
              FileUtils.mkdir_p(dir)
              FileUtils.cp(src, dir)
            end
          end
        end
      RUBY
    end
  end

  context "with a `FileUtils` method call and a `FileUtils` constant reference" do
    it "counts only the method call and does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class Backup
          def run
            FileUtils.mkdir_p(FileUtils::VERSION)
          end
        end
      RUBY
    end
  end

  context "with two `FileUtils` calls at the top level (no class/module)" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        FileUtils.mkdir_p(dir)
        FileUtils.cp(src, dir)
      RUBY
    end
  end

  context "with two calls on a different receiver" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class Reader
          def run
            File.read(a)
            File.read(b)
          end
        end
      RUBY
    end
  end
end
