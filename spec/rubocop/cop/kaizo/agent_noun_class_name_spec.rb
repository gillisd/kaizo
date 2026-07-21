RSpec.describe RuboCop::Cop::Kaizo::AgentNounClassName, :config do
  let(:cop_config) do
    {
      "AllowedSuffixes" => %w[Controller Router Parser User Order],
      "ForbiddenSuffixes" => %w[Service Util Utils],
    }
  end

  it "registers an offense for a class name ending in -er" do
    expect_offense(<<~RUBY)
      class OrderManager
            ^^^^^^^^^^^^ Avoid the doer-style class name `OrderManager`. Prefer a name for the concept it models over the action it performs.
      end
    RUBY
  end

  it "registers an offense for a class name ending in -or" do
    expect_offense(<<~RUBY)
      class PaymentProcessor
            ^^^^^^^^^^^^^^^^ Avoid the doer-style class name `PaymentProcessor`. Prefer a name for the concept it models over the action it performs.
      end
    RUBY
  end

  it "does not flag a class whose name is itself an allowed word" do
    expect_no_offenses(<<~RUBY)
      class User
      end
    RUBY
  end

  it "does not flag a class whose name ends in an allowed suffix" do
    expect_no_offenses(<<~RUBY)
      class UsersController
      end
    RUBY
  end

  it "does not flag a class that ends in neither -er nor -or" do
    expect_no_offenses(<<~RUBY)
      class Invoice
      end
    RUBY
  end

  it "registers an offense for a forbidden suffix that does not end in -er/-or" do
    expect_offense(<<~RUBY)
      class OrderService
            ^^^^^^^^^^^^ Avoid the doer-style class name `OrderService`. Prefer a name for the concept it models over the action it performs.
      end
    RUBY
  end

  it "registers an offense for the Util suffix" do
    expect_offense(<<~RUBY)
      class StringUtil
            ^^^^^^^^^^ Avoid the doer-style class name `StringUtil`. Prefer a name for the concept it models over the action it performs.
      end
    RUBY
  end

  it "demodulizes a namespaced class name" do
    expect_offense(<<~RUBY)
      class Billing::InvoiceBuilder
            ^^^^^^^^^^^^^^^^^^^^^^^ Avoid the doer-style class name `InvoiceBuilder`. Prefer a name for the concept it models over the action it performs.
      end
    RUBY
  end

  it "registers an offense for a class assigned from Struct.new" do
    expect_offense(<<~RUBY)
      Calculator = Struct.new(:input)
      ^^^^^^^^^^ Avoid the doer-style class name `Calculator`. Prefer a name for the concept it models over the action it performs.
    RUBY
  end

  it "registers an offense for a class assigned from Data.define" do
    expect_offense(<<~RUBY)
      Accumulator = Data.define(:total)
      ^^^^^^^^^^^ Avoid the doer-style class name `Accumulator`. Prefer a name for the concept it models over the action it performs.
    RUBY
  end

  it "does not flag an ordinary constant assignment" do
    expect_no_offenses(<<~RUBY)
      DEFAULT_TIMER = 30
    RUBY
  end

  context "when a suffix is both allowed and forbidden" do
    let(:cop_config) do
      { "AllowedSuffixes" => %w[Server], "ForbiddenSuffixes" => %w[Server] }
    end

    it "flags it, because ForbiddenSuffixes wins" do
      expect_offense(<<~RUBY)
        class ApiServer
              ^^^^^^^^^ Avoid the doer-style class name `ApiServer`. Prefer a name for the concept it models over the action it performs.
        end
      RUBY
    end
  end
end
