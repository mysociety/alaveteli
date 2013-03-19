# See https://makandracards.com/makandra/9443-rails-2-s-cookiestore-produces-invalid-cookie-data-causing-tests-to-break

# Should be able to remove this when we upgrade to Rails 3

module ActionController
  module Session
    CookieStore.class_eval do

      def call_with_line_break_fix(*args)
        status, headers, body = call_without_line_break_fix(*args)
        headers['Set-Cookie'].gsub! "\n\n", "\n" if headers['Set-Cookie'].present?
        [ status, headers, body ]
      end

      alias_method_chain :call, :line_break_fix

    end
  end
end