# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec/rails'

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures'

  # You can declare fixtures for each behaviour like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so here, like so ...
  #
  #   config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
end

# XXX No idea what namespace/class/module to put this in 
def receive_incoming_mail(email_name, email_to)
    email_name = File.join(Spec::Runner.configuration.fixture_path, email_name)
    content = File.read(email_name)
    content.gsub!('EMAIL_TO', email_to)
    RequestMailer.receive(content)
end

# Monkeypatch! Validate HTML in tests.
$tempfilecount = 0
module ActionController
    module TestProcess
        alias :original_process :process

        def process(action, parameters = nil, session = nil, flash = nil)
            # Call original process function
            self.original_process(action, parameters, session, flash)

            # And then validate if HTML
            if @response.content_type == "text/html" and @response.response_code != 302
                $tempfilecount = $tempfilecount + 1
                tempfilename = File.join(Dir::tmpdir, "railshtmlvalidate."+$$.to_s+"."+$tempfilecount.to_s+".html")
                File.open(tempfilename, "w+") do |f|
                    f.puts @response.body
                end
                if not system("/usr/bin/validate", tempfilename)
                    raise "HTML validation error in " + tempfilename + " HTTP status: " + @response.response_code.to_s
                end
                File.unlink(tempfilename)
            end
        end
    end
end



