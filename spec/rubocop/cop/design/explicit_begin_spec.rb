RSpec.describe RuboCop::Cop::Design::ExplicitBegin, :config do
  context "with an `ensure` clause attached directly to `def`" do
    it "registers an offense and wraps the body in an explicit begin" do
      expect_offense(<<~RUBY)
        def bar
          puts foo
        ensure
        ^^^^^^ Use an explicit `begin` block for `rescue`/`ensure` in a method body.
          file.close
        end
      RUBY

      expect_correction(<<~RUBY)
        def bar
          begin
            puts foo
          ensure
            file.close
          end
        end
      RUBY
    end
  end

  context "with a `rescue` clause attached directly to `def`" do
    it "registers an offense and wraps the body in an explicit begin" do
      expect_offense(<<~RUBY)
        def bar
          foo
        rescue KeyError => e
        ^^^^^^ Use an explicit `begin` block for `rescue`/`ensure` in a method body.
          handle(e)
        end
      RUBY

      expect_correction(<<~RUBY)
        def bar
          begin
            foo
          rescue KeyError => e
            handle(e)
          end
        end
      RUBY
    end
  end

  context "with rescue/else/ensure clauses combined" do
    it "registers an offense on the first clause and corrects the whole chain" do
      expect_offense(<<~RUBY)
        def bar
          foo
        rescue KeyError
        ^^^^^^ Use an explicit `begin` block for `rescue`/`ensure` in a method body.
          recover
        else
          celebrate
        ensure
          cleanup
        end
      RUBY

      expect_correction(<<~RUBY)
        def bar
          begin
            foo
          rescue KeyError
            recover
          else
            celebrate
          ensure
            cleanup
          end
        end
      RUBY
    end
  end

  context "with a singleton method definition (`defs`)" do
    it "registers an offense and wraps the body in an explicit begin" do
      expect_offense(<<~RUBY)
        def self.bar
          foo
        ensure
        ^^^^^^ Use an explicit `begin` block for `rescue`/`ensure` in a method body.
          cleanup
        end
      RUBY

      expect_correction(<<~RUBY)
        def self.bar
          begin
            foo
          ensure
            cleanup
          end
        end
      RUBY
    end
  end

  context "when the definition is nested inside a class" do
    it "preserves relative indentation in the correction" do
      expect_offense(<<~RUBY)
        class C
          def bar
            foo
          ensure
          ^^^^^^ Use an explicit `begin` block for `rescue`/`ensure` in a method body.
            cleanup
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class C
          def bar
            begin
              foo
            ensure
              cleanup
            end
          end
        end
      RUBY
    end
  end

  context "when the definition is on a single line" do
    it "registers an offense but does not autocorrect" do
      expect_offense(<<~RUBY)
        def bar; foo; rescue; nil; end
                      ^^^^^^ Use an explicit `begin` block for `rescue`/`ensure` in a method body.
      RUBY

      expect_no_corrections
    end
  end

  context "when the body contains a heredoc" do
    it "registers an offense but does not autocorrect" do
      expect_offense(<<~RUBY)
        def bar
          puts(<<~TEXT)
            hello
          TEXT
        ensure
        ^^^^^^ Use an explicit `begin` block for `rescue`/`ensure` in a method body.
          cleanup
        end
      RUBY

      expect_no_corrections
    end
  end

  context "with an explicit begin block" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        def bar
          begin
            foo
          ensure
            cleanup
          end
        end
      RUBY
    end
  end

  context "with a modifier rescue" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        def bar
          foo rescue nil
        end
      RUBY
    end
  end

  context "with an endless method definition", :ruby30 do
    it "does not register an offense for a modifier rescue body" do
      expect_no_offenses(<<~RUBY)
        def bar = (foo rescue nil)
      RUBY
    end
  end

  context "with a plain method body" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        def bar
          foo
        end
      RUBY
    end
  end

  context "with an empty method" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        def bar
        end
      RUBY
    end
  end
end
