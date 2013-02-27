# models/application_mailer.rb:
# Shared code between different mailers.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/

require 'action_mailer/version'
class ApplicationMailer < ActionMailer::Base
    # Include all the functions views get, as emails call similar things.
    helper :application
    include MailerHelper

    # This really should be the default - otherwise you lose any information
    # about the errors, and have to do error checking on return codes.
    self.raise_delivery_errors = true

    def blackhole_email
        Configuration::blackhole_prefix+"@"+Configuration::incoming_email_domain
    end

    # URL generating functions are needed by all controllers (for redirects),
    # views (for links) and mailers (for use in emails), so include them into
    # all of all.
    include LinkToHelper

    # Site-wide access to configuration settings
    include ConfigHelper

    # For each multipart template (e.g. "the_template_file.text.html.erb") available,
    # add the one from the view path with the highest priority as a part to the mail
    def render_multipart_templates
        added_content_types = {}
        self.view_paths.each do |view_path|
            Dir.glob("#{view_path}/#{mailer_name}/#{@template}.*").each do |path|
              template = view_path["#{mailer_name}/#{File.basename(path)}"]

              # Skip unless template has a multipart format
              next unless template && template.multipart?
              next if added_content_types[template.content_type] == true
              @parts << Part.new(
                :content_type => template.content_type,
                :disposition => "inline",
                :charset => charset,
                :body => render_message(template, @body)
              )
              added_content_types[template.content_type] = true
            end
        end
    end

    # Look for the current template in each element of view_paths in order,
    # return the first
    def find_template
        self.view_paths.each do |view_path|
            if template = view_path["#{mailer_name}/#{@template}"]
                return template
            end
        end
        return nil
    end
end

