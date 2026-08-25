RSpec.describe RuboCop::Cop::Kaizo::TotalArguments, :config do
  context "with `Max: 3`" do
    let(:cop_config) { { "Max" => 3 } }

    it "registers an offense for a `def` with too many positional arguments" do
      expect_offense(<<~RUBY)
        def calculate_volume(width, length, height, shape_type)
            ^^^^^^^^^^^^^^^^ Method has too many arguments. [4/3]
        end
      RUBY
    end

    it "counts positional and keyword arguments together" do
      expect_offense(<<~RUBY)
        def build(model, scope, page:, per_page:)
            ^^^^^ Method has too many arguments. [4/3]
        end
      RUBY
    end

    it "does not register an offense at exactly the maximum" do
      expect_no_offenses(<<~RUBY)
        def add_item(item, quantity: 1, note: nil)
        end
      RUBY
    end

    it "does not count splat, double-splat, or block arguments" do
      expect_no_offenses(<<~RUBY)
        def collect(first, second, third, *rest, **opts, &block)
        end
      RUBY
    end

    it "checks singleton method definitions (`def self.`)" do
      expect_offense(<<~RUBY)
        def self.create(a, b, c, d)
                 ^^^^^^ Method has too many arguments. [4/3]
        end
      RUBY
    end

    it "checks `define_method` blocks" do
      expect_offense(<<~RUBY)
        define_method(:process) { |a, b, c, d| nil }
        ^^^^^^^^^^^^^ Method has too many arguments. [4/3]
      RUBY
    end

    it "checks `define_singleton_method` blocks" do
      expect_offense(<<~RUBY)
        obj.define_singleton_method(:run) { |a, b, c, d| nil }
            ^^^^^^^^^^^^^^^^^^^^^^^ Method has too many arguments. [4/3]
      RUBY
    end

    it "ignores ordinary blocks" do
      expect_no_offenses(<<~RUBY)
        [1, 2].each { |first, second, third, fourth| nil }
      RUBY
    end

    it "ignores `define_method` blocks using numbered parameters" do
      expect_no_offenses(<<~RUBY)
        define_method(:doubled) { _1 * 2 }
      RUBY
    end
  end

  context "with an operator method" do
    let(:cop_config) { { "Max" => 1 } }

    it "exempts element assignment (`[]=`)" do
      expect_no_offenses(<<~RUBY)
        def []=(key, value)
        end
      RUBY
    end

    it "exempts a singleton operator definition (`def self.[]=`)" do
      expect_no_offenses(<<~RUBY)
        def self.[]=(key, value)
        end
      RUBY
    end

    it "still registers an offense for a non-operator method" do
      expect_offense(<<~RUBY)
        def store(key, value)
            ^^^^^ Method has too many arguments. [2/1]
        end
      RUBY
    end
  end

  context "with a `Struct.new` / `Data.define` value object" do
    let(:cop_config) { { "Max" => 3 } }

    it "exempts the `initialize` of a `Struct.new` block" do
      expect_no_offenses(<<~RUBY)
        Struct.new(:width, :height, :depth, :weight) do
          def initialize(width:, height:, depth:, weight:)
          end
        end
      RUBY
    end

    it "exempts the `initialize` of a `Data.define` block" do
      expect_no_offenses(<<~RUBY)
        Data.define(:a, :b, :c, :d) do
          def initialize(a:, b:, c:, d:)
          end
        end
      RUBY
    end

    it "exempts `initialize` when the block defines other methods too" do
      expect_no_offenses(<<~RUBY)
        Struct.new(:width, :height, :depth, :weight) do
          def initialize(width:, height:, depth:, weight:)
            super
          end

          def magnitude
            0
          end
        end
      RUBY
    end

    it "still checks non-initialize methods inside the block" do
      expect_offense(<<~RUBY)
        Struct.new(:value) do
          def transform(a, b, c, d)
              ^^^^^^^^^ Method has too many arguments. [4/3]
          end
        end
      RUBY
    end
  end

  context "with `AllowedMethods`" do
    let(:cop_config) { { "Max" => 1, "AllowedMethods" => ["initialize"] } }

    it "exempts a listed method" do
      expect_no_offenses(<<~RUBY)
        def initialize(host, port: 80)
        end
      RUBY
    end

    it "still registers an offense for an unlisted method" do
      expect_offense(<<~RUBY)
        def connect(host, port: 80)
            ^^^^^^^ Method has too many arguments. [2/1]
        end
      RUBY
    end
  end

  context "with the shipped default configuration" do
    subject(:shipped_cop) { described_class.new(shipped_config) }

    let(:shipped_config) { RuboCop::ConfigLoader.load_file("config/default.yml") }

    it "skips spec trees, so the keyword exemption is not re-policed through the total" do
      builder = project_path("spec/support/builders.rb")
      expect(shipped_cop.relevant_file?(builder)).to be(false)
    end

    it "skips test trees" do
      builder = project_path("test/support/builders.rb")
      expect(shipped_cop.relevant_file?(builder)).to be(false)
    end

    it "inspects application code" do
      model = project_path("app/models/order.rb")
      expect(shipped_cop.relevant_file?(model)).to be(true)
    end

    def project_path(relative)
      "#{Dir.pwd}/#{relative}"
    end
  end
end
