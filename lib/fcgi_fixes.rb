# Changed by mySociety 2008-03-10 to get dynamic FastCGI working.
# See also http://dev.rubyonrails.org/ticket/5399 - gah!

# Hopefully fixed in later Rails. There is a test in spec/libs/fcgi_handler.rb

require 'railties/lib/fcgi_handler.rb'

# Monkeypatch!
RailsFCGIHandler::SIGNALS['TERM'] = :exit

