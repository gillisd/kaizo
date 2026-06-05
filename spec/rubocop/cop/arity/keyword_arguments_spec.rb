# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Arity::KeywordArguments, :config do
  context 'with `Max: 2`' do
    let(:cop_config) { { 'Max' => 2, 'Min' => 0 } }

    it 'registers an offense for too many keyword arguments' do
      expect_offense(<<~RUBY)
        def calculate_volume(width:, length:, height:)
            ^^^^^^^^^^^^^^^^ Method has too many keyword arguments. [3/2]
        end
      RUBY
    end

    it 'counts optional keyword arguments' do
      expect_offense(<<~RUBY)
        def connect(host:, port: 80, ssl: true)
            ^^^^^^^ Method has too many keyword arguments. [3/2]
        end
      RUBY
    end

    it 'does not count positional arguments' do
      expect_no_offenses(<<~RUBY)
        def build(a, b, c, name:)
        end
      RUBY
    end

    it 'checks `define_method` blocks' do
      expect_offense(<<~RUBY)
        define_method(:render) { |format:, layout:, locals:| nil }
        ^^^^^^^^^^^^^ Method has too many keyword arguments. [3/2]
      RUBY
    end
  end
end
