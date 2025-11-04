require 'rubocop'

module CustomCops
  # Enforces empty line before rescued exceptions. Enforces no empty line after
  # rescued exceptions.
  #
  # @example
  #   # bad
  #   begin
  #     do_something
  #     do_something_else
  #   rescue FooError
  #     error_notification
  #     handle_error
  #   end
  #
  #   # good
  #   begin
  #     do_something
  #     do_something_else
  #
  #   rescue FooError
  #     error_notification
  #     handle_error
  #   end
  #
  #   # bad
  #   begin
  #     do_something
  #     do_something_else
  #
  #   rescue FooError
  #
  #     error_notification
  #     handle_error
  #   end
  #
  #   # good
  #   begin
  #     do_something
  #     do_something_else
  #
  #   rescue FooError
  #     error_notification
  #     handle_error
  #   end
  #
  class EmptyLinesAroundRescuedExceptions < RuboCop::Cop::Base
    extend RuboCop::Cop::AutoCorrector
    include RuboCop::Cop::RangeHelp

    MSG_BEFORE = 'Use empty line before rescued exceptions.'
    MSG_AFTER = 'Avoid empty line after rescued exceptions.'

    def on_rescue(node)
      return unless node.body.multiline?

      node.resbody_branches.each do |resbody|
        next unless resbody.body && resbody.body.multiline?

        preceding_line = processed_source[resbody.first_line - 2]
        unless preceding_line.blank?
          add_offense(resbody, message: MSG_BEFORE) do |corrector|
            range = range_by_whole_lines(resbody.source_range)
            corrector.insert_before(range, "\n")
          end
        end

        first_line = processed_source[resbody.body.first_line - 2]
        if first_line.blank?
          add_offense(resbody, message: MSG_AFTER) do |corrector|
            corrector.remove(range_of_first_line(resbody.body))
          end
        end
      end
    end

    private

    def range_of_first_line(node)
      buffer = processed_source.buffer
      first_line = node.children.first.loc.first_line - 1
      begin_pos = buffer.line_range(first_line).begin_pos
      end_pos = begin_pos + buffer.source_line(first_line).length + 1
      Parser::Source::Range.new(buffer, begin_pos, end_pos)
    end
  end
end
