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

    # Instantiate a new mailer object. If +method_name+ is not +nil+, the mailer
    # will be initialized according to the named method. If not, the mailer will
    # remain uninitialized (useful when you only need to invoke the "receive"
    # method, for instance).
    def initialize(method_name=nil, *parameters) #:nodoc:
      create!(method_name, *parameters) if method_name
    end

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

    if ActionMailer::VERSION::MAJOR == 2

        # This method is a customised version of ActionMailer::Base.create!
        # modified to allow templates to be selected correctly for multipart
        # mails when themes have added to the view_paths. The problem from our
        # point of view with ActionMailer::Base is that it sets template_root to
        # the first element of the view_paths array and then uses only that (directly
        # and via template_path, which is created from it) in the create! method when
        # looking for templates. Our modified version looks for templates in the view_paths
        # in order.

        # It also has a line converting the mail subject to a string. This is because we
        # use translated strings in the subject lines, sometimes in conjunction with
        # user input, like request titles. The _() function used for translation
        # returns an instance of SafeBuffer, which doesn't handle gsub calls in the block form
        # with $ variables - https://github.com/rails/rails/issues/1555.
        # Unfortunately ActionMailer uses that form in quoted_printable(), which will be
        # called if any part of the subject requires quoting. So we convert the subject
        # back to a string via to_str() before passing in to create_mail. There is a test
        # for this in spec/models/request_mailer_spec.rb

        # Changed lines marked with ***

        # Initialize the mailer via the given +method_name+. The body will be
        # rendered and a new TMail::Mail object created.
        def create!(method_name, *parameters) #:nodoc:
          initialize_defaults(method_name)
          __send__(method_name, *parameters)

          # If an explicit, textual body has not been set, we check assumptions.
          unless String === @body
            # First, we look to see if there are any likely templates that match,
            # which include the content-type in their file name (i.e.,
            # "the_template_file.text.html.erb", etc.). Only do this if parts
            # have not already been specified manually.
            if @parts.empty?
              # *** render_multipart_templates replaces the following code
              # Dir.glob("#{template_path}/#{@template}.*").each do |path|
              #   template = template_root["#{mailer_name}/#{File.basename(path)}"]
              #
              #   # Skip unless template has a multipart format
              #   next unless template && template.multipart?
              #
              #   @parts << Part.new(
              #     :content_type => template.content_type,
              #     :disposition => "inline",
              #     :charset => charset,
              #     :body => render_message(template, @body)
              #   )
              # end
              render_multipart_templates

              unless @parts.empty?
                @content_type = "multipart/alternative" if @content_type !~ /^multipart/
                @parts = sort_parts(@parts, @implicit_parts_order)
              end
            end

            # Then, if there were such templates, we check to see if we ought to
            # also render a "normal" template (without the content type). If a
            # normal template exists (or if there were no implicit parts) we render
            # it.
            template_exists = @parts.empty?

            # *** find_template replaces template_root call
            # template_exists ||= template_root["#{mailer_name}/#{@template}"]
            template_exists ||= find_template

            @body = render_message(@template, @body) if template_exists

            # Finally, if there are other message parts and a textual body exists,
            # we shift it onto the front of the parts and set the body to nil (so
            # that create_mail doesn't try to render it in addition to the parts).
            if !@parts.empty? && String === @body
              @parts.unshift ActionMailer::Part.new(:charset => charset, :body => @body)
              @body = nil
            end
          end

          # If this is a multipart e-mail add the mime_version if it is not
          # already set.
          @mime_version ||= "1.0" if !@parts.empty?

          # *** Convert into a string
          @subject = @subject.to_str if @subject

          # build the mail object itself
          @mail = create_mail
        end
    else
        raise "ApplicationMailer.create! is obsolete - find another way to ensure that themes can override mail templates for multipart mails"
    end

end

