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
$html_validation_script = "/usr/bin/validate" # from Debian package wdg-html-validator
if $tempfilecount.nil?
    $tempfilecount = 0
    if File.exist?($html_validation_script)
        module ActionController
            module TestProcess
                # Hook into the process function, so can automatically get HTML after each request
                alias :original_process :process

                def process(action, parameters = nil, session = nil, flash = nil)
                    # Call original process function
                    self.original_process(action, parameters, session, flash)

                    # And then if HTML, not a redirect (302), and not a partial template (something/_something, such as in AJAX partial results)
                    if @response.content_type == "text/html" and @response.response_code != 302 and not @response.rendered_file.include?("/_")
                        $tempfilecount = $tempfilecount + 1
                        tempfilename = File.join(Dir::tmpdir, "railshtmlvalidate."+$$.to_s+"."+$tempfilecount.to_s+".html")
                        File.open(tempfilename, "w+") do |f|
                            f.puts @response.body
                        end
                        if not system($html_validation_script, tempfilename)
                            raise "HTML validation error in " + tempfilename + " HTTP status: " + @response.response_code.to_s
                        end
                        File.unlink(tempfilename)
                    end
                end
            end
        end
    else
        puts "WARNING: HTML validation script " + $html_validation_script + " not found"
    end
end


