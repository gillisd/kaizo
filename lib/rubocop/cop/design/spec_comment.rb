module RuboCop
  module Cop
    module Design
      # Checks for comments in spec files.
      #
      # A comment in a spec is almost always a sign that the spec is doing the
      # job of its own description. If you need a sentence to explain what an
      # example sets up or asserts, that sentence usually wants to be a
      # `context`/`it` description, a clearer example name, or another example --
      # not prose riding alongside the code.
      #
      # By default only `*_spec.rb` files are inspected (see `Include`). Magic
      # comments (`# frozen_string_literal: true`, `# encoding: ...`), RuboCop
      # directives (`# rubocop:disable`/`# rubocop:enable`), and shebangs are
      # never flagged; add further exemptions with `AllowedPatterns`. There is no
      # autocorrection: turning an explanation into a spec is a design decision.
      #
      # @example
      #   # bad
      #   it 'permits the request' do
      #     # an admin can see everything
      #     user = create(:user, admin: true)
      #     expect(policy).to permit(user)
      #   end
      #
      #   # good
      #   it 'permits an admin to see everything' do
      #     admin = create(:user, admin: true)
      #     expect(policy).to permit(admin)
      #   end
      #
      class SpecComment < Base
        include AllowedPattern

        MSG = "Avoid comments in specs. Express the intent as a `context`/`it` " \
              "description or a clearer example instead.".freeze

        def on_new_investigation
          processed_source.comments.each do |comment|
            next if allowed?(comment)

            add_offense(comment)
          end
        end

        private

        def allowed?(comment)
          magic_comment?(comment) ||
            directive_comment?(comment) ||
            shebang?(comment) ||
            matches_allowed_pattern?(comment.text)
        end

        def magic_comment?(comment)
          MagicComment.parse(comment.text).any?
        end

        def directive_comment?(comment)
          DirectiveComment.new(comment).start_with_marker?
        end

        def shebang?(comment)
          comment.text.start_with?("#!")
        end
      end
    end
  end
end
