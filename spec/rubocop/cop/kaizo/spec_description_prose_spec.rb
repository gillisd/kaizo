RSpec.describe RuboCop::Cop::Kaizo::SpecDescriptionProse, :config do
  context "with a comma in an `it` description" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        it "renders the name, image"
           ^^^^^^^^^^^^^^^^^^^^^^^^^ Split this example: its description contains a comma.
      RUBY
    end
  end

  context "with a coordinating conjunction in an `it` description" do
    it "registers an offense for `and`" do
      expect_offense(<<~RUBY)
        it "appends the container and returns it"
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Split this example: its description contains `and`; use separate examples or a `context`.
      RUBY
    end

    it "registers an offense for `or`" do
      expect_offense(<<~RUBY)
        it "accepts a symbol or a string"
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Split this example: its description contains `or`; use separate examples or a `context`.
      RUBY
    end
  end

  context "with a conditional word in an `it` description" do
    it "registers an offense for `when`" do
      expect_offense(<<~RUBY)
        it "omits the key when the role is unset"
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Split this example: its description contains `when`; use separate examples or a `context`.
      RUBY
    end
  end

  context "with code in an `it` description" do
    it "registers an offense for a symbol" do
      expect_offense(<<~RUBY)
        it "omits the :cpu key"
           ^^^^^^^^^^^^^^^^^^^^ Write the description as prose; it contains code, not English.
      RUBY
    end

    it "registers an offense for an underscored identifier" do
      expect_offense(<<~RUBY)
        it "converts memory_gb to strings"
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Write the description as prose; it contains code, not English.
      RUBY
    end

    it "registers an offense for a nested quoted literal" do
      expect_offense(<<~RUBY)
        it 'renders "FARGATE"'
           ^^^^^^^^^^^^^^^^^^^ Write the description as prose; it contains code, not English.
      RUBY
    end
  end

  context "with a well-formed `it` description" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        it "renders the name"
      RUBY
    end

    it "does not flag a conjunction embedded in a word" do
      expect_no_offenses(<<~RUBY)
        it "understands the format"
      RUBY
    end

    it "does not flag `for`, which is a preposition here" do
      expect_no_offenses(<<~RUBY)
        it "renders the value for the id"
      RUBY
    end
  end

  context "with a block-form example" do
    it "still flags the description" do
      expect_offense(<<~RUBY)
        it "renders the name and the image" do
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Split this example: its description contains `and`; use separate examples or a `context`.
          expect(subject).to be_present
        end
      RUBY
    end
  end

  context "with a non-string example description" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        it { is_expected.to eq(1) }
      RUBY
    end
  end

  context "with code in a `context` description" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        context "with a memory_gb value" do
                ^^^^^^^^^^^^^^^^^^^^^^^^ Write the context description as prose; it contains code, not English.
        end
      RUBY
    end
  end

  context "with a `context` description that does not open with a condition word" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        context "the role is unset" do
                ^^^^^^^^^^^^^^^^^^^ Begin the context description with `when`/`with`/`without`/`after`.
        end
      RUBY
    end
  end

  context "with a well-formed `context` description" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        context "when the role is unset" do
          it "omits the key"
        end
      RUBY
    end
  end

  context "with a `describe` string" do
    it "is exempt even when it names a method" do
      expect_no_offenses(<<~RUBY)
        describe "#to_h" do
        end
      RUBY
    end
  end
end
