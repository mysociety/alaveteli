# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path(File.join('..', '..', 'config', 'environment'), __FILE__)
require 'spec/autorun'
require 'spec/rails'

# set a default username and password so we can test 
config = MySociety::Config.load_default()
config['ADMIN_USERNAME'] = 'foo'
config['ADMIN_PASSWORD'] = 'baz'

# tests assume 20 days
config['REPLY_LATE_AFTER_DAYS'] = 20


# Uncomment the next line to use webrat's matchers
#require 'webrat/integrations/rspec-rails'

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb

  # fixture_path must end in a separator
  config.fixture_path = File.join(Rails.root, 'spec', 'fixtures') + File::SEPARATOR

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses its own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  #
  # For more information take a look at Spec::Runner::Configuration and Spec::Runner
end

# XXX No idea what namespace/class/module to put this in 
def receive_incoming_mail(email_name, email_to, email_from = 'geraldinequango@localhost')
    email_name = file_fixture_name(email_name)
    content = File.read(email_name)
    content.gsub!('EMAIL_TO', email_to)
    content.gsub!('EMAIL_FROM', email_from)
    RequestMailer.receive(content)
end

def file_fixture_name(file_name)
    return File.join(Spec::Runner.configuration.fixture_path, "files", file_name)
end

def load_file_fixture(file_name)
    file_name = file_fixture_name(file_name)
    content = File.read(file_name)
    return content
end

def rebuild_xapian_index
    # XXX could for speed call ActsAsXapian.rebuild_index directly, but would
    # need model name list, and would need to fix acts_as_xapian so can call writes
    # and reads mixed up (it asserts where it thinks it can't do this)
    rebuild_name = File.dirname(__FILE__) + '/../script/rebuild-xapian-index'
    Kernel.system(rebuild_name) or raise "failed to launch #{rebuild_name}, error bitcode #{$?}, exit status: #{$?.exitstatus}"
end

def update_xapian_index
    verbose = false
    ActsAsXapian.update_index(flush_to_disk=true, verbose) 
end

# Validate an entire HTML page
def validate_html(html)
    $tempfilecount = $tempfilecount + 1
    tempfilename = File.join(Dir::tmpdir, "railshtmlvalidate."+$$.to_s+"."+$tempfilecount.to_s+".html")
    File.open(tempfilename, "w+") do |f|
        f.puts html
    end
    if not system($html_validation_script, tempfilename)
        raise "HTML validation error in " + tempfilename + " HTTP status: " + @response.response_code.to_s
    end
    File.unlink(tempfilename)
    return true
end

# Validate HTML fragment by wrapping it as the <body> of a page
def validate_as_body(html)
    validate_html('<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">' +
        "<html><head><title>Test</title></head><body>#{html}</body></html>")
end

def basic_auth_login(request, username = nil, password = nil)
   username = MySociety::Config.get('ADMIN_USERNAME') if username.nil?
    password = MySociety::Config.get('ADMIN_PASSWORD') if password.nil?
    request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64::encode64("#{username}:#{password}")
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

                def process(action, parameters = nil, session = nil, flash = nil, http_method = 'GET')
                    self.original_process(action, parameters, session, flash, http_method)

                    # XXX Is there a better way to check this than calling a private method?
                    return unless @response.template.controller.instance_eval { integrate_views? }

                    # And then if HTML, not a redirect (302, 301)
                    if @response.content_type == "text/html" && ! [301,302,401].include?(@response.response_code)
                        validate_html(@response.body)
                    end
                end
            end
        end
    else
        puts "WARNING: HTML validation script " + $html_validation_script + " not found"
    end
end

def load_raw_emails_data(raw_emails)
    raw_email = raw_emails(:useless_raw_email)
    begin
        raw_email.destroy_file_representation!
    rescue Errno::ENOENT
    end
    raw_email.data = load_file_fixture("useless_raw_email.email")
end
