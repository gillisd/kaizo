RSpec.describe RuboCop::Cop::Kaizo::SpecSubject, :config do
  context "with a `let` building `described_class`" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        RSpec.describe Session::Pool do
          let(:pool) { described_class.new }
          ^^^ Declare the unit under test with `subject(:pool)`, not `let`.
        end
      RUBY
    end

    it "registers an offense for a construction with arguments" do
      expect_offense(<<~RUBY)
        RSpec.describe Session::Pool do
          let(:pool) { described_class.new(size: 2) }
          ^^^ Declare the unit under test with `subject(:pool)`, not `let`.
        end
      RUBY
    end

    it "registers an offense for `let!`" do
      expect_offense(<<~RUBY)
        RSpec.describe Session::Pool do
          let!(:pool) { described_class.new }
          ^^^^ Declare the unit under test with `subject(:pool)`, not `let`.
        end
      RUBY
    end

    it "registers an offense when the construction is the final expression" do
      expect_offense(<<~RUBY)
        RSpec.describe Session::Pool do
          let(:pool) do
          ^^^ Declare the unit under test with `subject(:pool)`, not `let`.
            size = 2
            described_class.new(size)
          end
        end
      RUBY
    end
  end

  context "with a `let` naming the described constant" do
    it "registers an offense for the full constant" do
      expect_offense(<<~RUBY)
        RSpec.describe Session::Pool do
          let(:pool) { Session::Pool.new }
          ^^^ Declare the unit under test with `subject(:pool)`, not `let`.
        end
      RUBY
    end

    it "registers an offense for the constant's short name" do
      expect_offense(<<~RUBY)
        RSpec.describe Session::Pool do
          let(:pool) { Pool.new }
          ^^^ Declare the unit under test with `subject(:pool)`, not `let`.
        end
      RUBY
    end

    it "registers an offense inside a nested context" do
      expect_offense(<<~RUBY)
        RSpec.describe Session::Pool do
          context "when empty" do
            let(:pool) { Pool.new }
            ^^^ Declare the unit under test with `subject(:pool)`, not `let`.
          end
        end
      RUBY
    end
  end

  context "with a `let` naming the class the file is named after" do
    it "registers an offense" do
      expect_offense(<<~RUBY, "spec/session/pool_spec.rb")
        RSpec.describe "a session pool" do
          let(:pool) { Pool.new }
          ^^^ Declare the unit under test with `subject(:pool)`, not `let`.
        end
      RUBY
    end

    it "matches a multi-word file name against the camelized class" do
      expect_offense(<<~RUBY, "spec/api_client_spec.rb")
        RSpec.describe "the client" do
          let(:client) { APIClient.new }
          ^^^ Declare the unit under test with `subject(:client)`, not `let`.
        end
      RUBY
    end

    it "does not register an offense for a class unrelated to the file name" do
      expect_no_offenses(<<~RUBY, "spec/session/pool_spec.rb")
        RSpec.describe "a session pool" do
          let(:queue) { Queue.new }
        end
      RUBY
    end
  end

  context "with a `let` that is not the unit under test" do
    it "does not register an offense for another class" do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Session::Pool do
          let(:logger) { Logger.new }
        end
      RUBY
    end

    it "does not register an offense for a body that only uses described_class" do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Session::Pool do
          let(:name) { described_class.name }
        end
      RUBY
    end

    it "does not register an offense for a collection of instances" do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Session::Pool do
          let(:pools) { [described_class.new, described_class.new] }
        end
      RUBY
    end
  end

  context "with a `subject` declaration" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Session::Pool do
          subject(:pool) { described_class.new }
        end
      RUBY
    end
  end

  context "with `AllowedMethods`" do
    let(:cop_config) { { "AllowedMethods" => ["other"] } }

    it "does not register an offense for a listed let name" do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Session::Pool do
          subject(:pool) { described_class.new }

          let(:other) { described_class.new }
        end
      RUBY
    end
  end

  context "with `AllowedPatterns`" do
    let(:cop_config) { { "AllowedPatterns" => ["\\Aother_"] } }

    it "does not register an offense for a matching let name" do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Session::Pool do
          let(:other_pool) { described_class.new }
        end
      RUBY
    end
  end
end
