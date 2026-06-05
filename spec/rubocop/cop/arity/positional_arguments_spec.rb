# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Arity::PositionalArguments, :config do
  context 'with `Max: 2`' do
    let(:cop_config) { { 'Max' => 2 } }

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
end
