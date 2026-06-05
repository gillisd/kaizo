# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Arity::PositionalArguments, :config do
  context 'with `Max: 2`' do
    let(:cop_config) { { 'Max' => 2, 'Min' => 0 } }

    it 'registers an offense for too many positional arguments' do
      expect_offense(<<~RUBY)
        def move(x, y, z)
            ^^^^ Method has too many positional arguments. [3/2]
        end
      RUBY
    end

    it 'counts optional positional arguments' do
      expect_offense(<<~RUBY)
        def scale(x, y = 1, z = 2)
            ^^^^^ Method has too many positional arguments. [3/2]
        end
      RUBY
    end

    it 'does not count keyword arguments' do
      expect_no_offenses(<<~RUBY)
        def configure(host, port:, timeout:, retries:)
        end
      RUBY
    end
  end

  context 'with `Min: 1`' do
    let(:cop_config) { { 'Min' => 1, 'Max' => 10 } }

    it 'registers an offense for too few positional arguments' do
      expect_offense(<<~RUBY)
        def search(query:)
            ^^^^^^ Method has too few positional arguments. [0/1]
        end
      RUBY
    end
  end
end
