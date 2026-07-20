RSpec.describe RuboCop::Cop::Design::FileUtilsInclusion, :config do
  context "with two `FileUtils` calls in a class" do
    it "registers an offense on each qualified call" do
      expect_offense(<<~RUBY)
        class Backup
          def run
            FileUtils.mkdir_p(dir)
            ^^^^^^^^^ `FileUtils` is used 2 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
            FileUtils.cp(src, dir)
            ^^^^^^^^^ `FileUtils` is used 2 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
          end
        end
      RUBY
    end
  end

  context "with two `FileUtils` calls in a module" do
    it "registers an offense reported as a module" do
      expect_offense(<<~RUBY)
        module Helpers
          def clean
            FileUtils.rm_rf(tmp)
            ^^^^^^^^^ `FileUtils` is used 2 times in this module; `include`/`extend` FileUtils and call its methods unqualified.
          end

          def seed
            FileUtils.touch(flag)
            ^^^^^^^^^ `FileUtils` is used 2 times in this module; `include`/`extend` FileUtils and call its methods unqualified.
          end
        end
      RUBY
    end
  end

  context "with `FileUtils` used in both an instance and a singleton method" do
    it "counts them together and reports each" do
      expect_offense(<<~RUBY)
        class Store
          def self.reset
            FileUtils.rm_rf(root)
            ^^^^^^^^^ `FileUtils` is used 2 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
          end

          def write
            FileUtils.mkdir_p(root)
            ^^^^^^^^^ `FileUtils` is used 2 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
          end
        end
      RUBY
    end
  end

  context "with three `FileUtils` calls" do
    it "reports the count as three" do
      expect_offense(<<~RUBY)
        class Backup
          def run
            FileUtils.mkdir_p(dir)
            ^^^^^^^^^ `FileUtils` is used 3 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
            FileUtils.cp(a, dir)
            ^^^^^^^^^ `FileUtils` is used 3 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
            FileUtils.chmod(0o755, dir)
            ^^^^^^^^^ `FileUtils` is used 3 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
          end
        end
      RUBY
    end
  end

  context "with a fully-qualified `::FileUtils`" do
    it "counts it and flags the qualified receiver" do
      expect_offense(<<~RUBY)
        class Backup
          def run
            ::FileUtils.mkdir_p(dir)
            ^^^^^^^^^^^ `FileUtils` is used 2 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
            ::FileUtils.cp(src, dir)
            ^^^^^^^^^^^ `FileUtils` is used 2 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
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
    it "flags only the nested class that owns them" do
      expect_offense(<<~RUBY)
        class Outer
          class Inner
            def run
              FileUtils.mkdir_p(dir)
              ^^^^^^^^^ `FileUtils` is used 2 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
              FileUtils.cp(src, dir)
              ^^^^^^^^^ `FileUtils` is used 2 times in this class; `include`/`extend` FileUtils and call its methods unqualified.
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
