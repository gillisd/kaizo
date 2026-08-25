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

  context "with an error class name in an `it` description" do
    it "does not flag a namespaced error constant" do
      expect_no_offenses(<<~RUBY)
        it "raises Foo::Error"
      RUBY
    end

    it "does not flag an exception-suffixed constant" do
      expect_no_offenses(<<~RUBY)
        it "raises Timeout::DeadlineException on a slow read"
      RUBY
    end

    it "still flags a conjunction alongside an error constant" do
      expect_offense(<<~RUBY)
        it "raises Foo::Error when the name is empty"
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Split this example: its description contains `when`; use separate examples or a `context`.
      RUBY
    end

    it "still flags code outside the error constant" do
      expect_offense(<<~RUBY)
        it "raises Foo::Error for the :cpu key"
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Write the description as prose; it contains code, not English.
      RUBY
    end
  end

  context "with an error class name in a `context` description" do
    it "does not flag the constant" do
      expect_no_offenses(<<~RUBY)
        context "when Foo::Error is raised" do
        end
      RUBY
    end
  end

  context "when AllowedPatterns permits a description" do
    let(:cop_config) { { "AllowedPatterns" => ["Foo::Widget"] } }

    it "does not flag a matching `it` description" do
      expect_no_offenses(<<~RUBY)
        it "returns a Foo::Widget"
      RUBY
    end

    it "does not flag a matching `context` description" do
      expect_no_offenses(<<~RUBY)
        context "with a Foo::Widget" do
        end
      RUBY
    end

    it "still flags a description the pattern does not match" do
      expect_offense(<<~RUBY)
        it "renders the :cpu key"
           ^^^^^^^^^^^^^^^^^^^^^^ Write the description as prose; it contains code, not English.
      RUBY
    end
  end

  context "with a custom `ForbiddenWords` list" do
    let(:cop_config) { { "ForbiddenWords" => ["sometimes"] } }

    it "flags the configured word" do
      expect_offense(<<~RUBY)
        it "sometimes renders the name"
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Split this example: its description contains `sometimes`; use separate examples or a `context`.
      RUBY
    end

    it "does not flag the default words the custom list replaced" do
      expect_no_offenses(<<~RUBY)
        it "appends the container and returns it"
      RUBY
    end
  end

  context "with a custom `RequiredContextPrefixes` list" do
    let(:cop_config) { { "RequiredContextPrefixes" => ["given"] } }

    it "accepts the configured prefix" do
      expect_no_offenses(<<~RUBY)
        context "given an admin role" do
        end
      RUBY
    end

    it "rejects a default prefix and names the configured ones" do
      expect_offense(<<~RUBY)
        context "when the role is unset" do
                ^^^^^^^^^^^^^^^^^^^^^^^^ Begin the context description with `given`.
        end
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
