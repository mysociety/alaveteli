# -*- encoding : utf-8 -*-
# app/controllers/help_controller.rb:
# Show information about one particular request.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class HelpController < ApplicationController

  # we don't even have a control subroutine for most help pages, just see their templates

  before_filter :long_cache
  before_filter :catch_spam, :only => [:contact]

  def index
    redirect_to help_about_path
  end

  def unhappy
    @country_code = AlaveteliConfiguration.iso_country_code
    @info_request = nil
    if params[:url_title]
      @info_request = InfoRequest
        .not_embargoed
          .find_by_url_title!(params[:url_title])
    end
  end

  def contact
    @contact_email = AlaveteliConfiguration::contact_email
    if feature_enabled?(:alaveteli_pro) && @user && @user.is_pro?
      @contact_email = AlaveteliConfiguration::pro_contact_email
    end

    # if they clicked remove for link to request/body, remove it
    if params[:remove]
      @last_request = nil
      cookies["last_request_id"] = nil
      cookies["last_body_id"] = nil
    end

    # look up link to request/body
    request = InfoRequest.find_by(id: cookies["last_request_id"].to_i)
    @last_request = request if can?(:read, request)

    @last_body = PublicBody.find_by(id: cookies["last_body_id"].to_i)

    # submit form
    if params[:submitted_contact_form]
      if @user
        params[:contact][:email] = @user.email
        params[:contact][:name] = @user.name
      end
      @contact = ContactValidator.new(params[:contact])
      if @contact.valid? && !params[:remove]
        ContactMailer.to_admin_message(
          params[:contact][:name],
          params[:contact][:email],
          params[:contact][:subject],
          params[:contact][:message],
          @user,
          @last_request, @last_body
        ).deliver_now
        flash[:notice] = _("Your message has been sent. Thank you for getting in touch! We'll get back to you soon.")
        redirect_to frontpage_url
        return
      end

      if params[:remove]
        @contact.errors.clear
      end
    end

  end

  private

  def catch_spam
    if request.post? && params[:contact]
      if !params[:contact][:comment].blank? || !params[:contact].key?(:comment)
        redirect_to frontpage_url
      end
    end
  end

end
