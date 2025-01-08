require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'
require Rails.root.join('lib/custom_cops/empty_lines_around_rescued_exceptions')

RSpec.describe CustomCops::EmptyLinesAroundRescuedExceptions, :config do
  include RuboCop::RSpec::ExpectOffense

  it 'registers no offense when rescue body is just a single line' do
    expect_no_offenses(<<~RUBY)
      begin
         do_something
       rescue FooError
         error_notification
         handle_error
      end
    RUBY
  end

  it 'registers no offense when resbody body is just a single line' do
    expect_no_offenses(<<~RUBY)
      begin
         do_something
         do_something_else
       rescue FooError
         handle_error
      end
    RUBY
  end

  it 'registers an offense for missing extra newlines before rescued exceptions' do
    expect_offense(<<~RUBY)
      begin
         do_something
         do_something_else
       rescue FooError
       ^^^^^^^^^^^^^^^ Use empty line before rescued exceptions.
         error_notification
         handle_error
      end
    RUBY

    expect_correction(<<~RUBY)
      begin
         do_something
         do_something_else

       rescue FooError
         error_notification
         handle_error
      end
    RUBY
  end

  it 'registers an offense for newlines after rescued exceptions' do
    expect_offense(<<~RUBY)
      begin
         do_something
         do_something_else

       rescue FooError
       ^^^^^^^^^^^^^^^ Avoid empty line after rescued exceptions.

         error_notification
         handle_error
      end
    RUBY

    expect_correction(<<~RUBY)
      begin
         do_something
         do_something_else

       rescue FooError
         error_notification
         handle_error
      end
    RUBY
  end
end
