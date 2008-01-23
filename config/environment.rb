# Be sure to restart your web server when you modify this file.


# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# MySociety specific helper functions
$:.push(File.join(File.dirname(__FILE__), '../../rblib'))

load "validate.rb"
load "config.rb"
load "format.rb"

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
  
  # Load intial mySociety config
  MySociety::Config.set_file(File.join(config.root_path, 'config', 'general'), true)
  MySociety::Config.load_default
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register "application/x-mobile", :mobile

# Validation error messages
ActiveRecord::Errors.default_error_messages[:blank] = "must be filled in"
# Monkeypatch! Use SPAN instead of DIV. See http://dev.rubyonrails.org/ticket/2210
ActionView::Base.field_error_proc = Proc.new{ |html_tag, instance|  %(<span class="fieldWithErrors">#{html_tag}</span>)}

# Include your application configuration below

# Monkeypatch! Output HTML 4.0 compliant code, using method described in this
# ticket: http://dev.rubyonrails.org/ticket/6009
ActionView::Helpers::TagHelper.module_eval do
  def tag(name, options = nil, open = false, escape = true)
    "<#{name}#{tag_options(options, escape) if options}" + (open ? ">" : ">")
  end
end

# Domain for URLs (so can work for scripts, not just web pages)
ActionController::UrlWriter.default_url_options[:host] = MySociety::Config.get("DOMAIN", 'localhost:3000')

# Monkeypatch! Set envelope from in ActionMailer. Code mostly taken from this
# Rails patch, with addition of using mail.from for sendmail if sender not set
# (the patch does that only for SMTP, when it clearly should consistently do it
# for both)
#   http://dev.rubyonrails.org/attachment/ticket/7697/action_mailer_base_sender.diff
# Which is part of this ticket:
#   http://dev.rubyonrails.org/ticket/7697
module ActionMailer
    class Base
        def perform_delivery_smtp(mail)
            destinations = mail.destinations
            sender = mail.sender(nil) || mail.from 
            mail.ready_to_send

            Net::SMTP.start(smtp_settings[:address], smtp_settings[:port], smtp_settings[:domain],
                smtp_settings[:user_name], smtp_settings[:password], smtp_settings[:authentication]) do |smtp|
                smtp.sendmail(mail.encoded, sender, destinations)
            end
        end

        def perform_delivery_sendmail(mail)
            sender = mail.sender(nil) || mail.from 

            arguments = sendmail_settings[:arguments].dup 
            arguments += " -f \"#{sender}\""
            IO.popen("#{sendmail_settings[:location]} #{arguments}","w+") do |sm| 
                sm.print(mail.encoded.gsub(/\r/, ''))
                sm.flush
            end
        end
    end
end

# Monkeypatch! Remove individual error messages from an ActiveRecord.
module ActiveRecord
    class Errors
        def delete(key)
            @errors.delete(key)
        end
    end
end

