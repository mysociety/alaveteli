# app/controllers/help_controller.rb:
# Show information about one particular request.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/
class HelpController < ApplicationController
  # we don't even have a control subroutine for most help pages, just see their
  # templates

  before_action :long_cache
  before_action :catch_spam, only: [:contact]
  before_action :set_recaptcha_required, only: [:contact]

  def index
    redirect_to help_about_path
  end

  def unhappy
    @country_code = AlaveteliConfiguration.iso_country_code
    @info_request = nil
    if params[:url_title]
      @info_request = InfoRequest.
        not_embargoed.
          find_by_url_title!(params[:url_title])
    end

    @refusal_advice = RefusalAdvice.default(@info_request)
  end

  def contact
    # if they clicked remove for link to request/body, remove it
    if params[:remove]
      @last_request = nil
      cookies['last_request_id'] = nil
      cookies['last_body_id'] = nil
    end

    # look up link to request/body
    request = InfoRequest.find_by(id: cookies['last_request_id'].to_i)
    @last_request = request if can?(:read, request)

    @last_body = PublicBody.find_by(id: cookies['last_body_id'].to_i)

    # submit form
    return unless params[:submitted_contact_form]

    if @user
      params[:contact][:email] = @user.email
      params[:contact][:name] = @user.name
    end

    if params[:remove]
      contact_validator.errors.clear

    elsif @recaptcha_required && !verify_recaptcha
      flash.now[:error] = _('There was an error with the reCAPTCHA. ' \
                            'Please try again.')
    elsif contact_validator.valid?
      contact_mailer.deliver_now
      flash[:notice] = _("Your message has been sent. Thank you for getting " \
                         "in touch! We'll get back to you soon.")
      redirect_to frontpage_url
    end
  end

  private

  def contact_validator
    @contact_validator ||= ContactValidator.new(contact_params)
  end

  def contact_mailer
    ContactMailer.to_admin_message(
      contact_params[:name],
      contact_params[:email],
      contact_params[:subject],
      contact_params[:message],
      @user, @last_request, @last_body
    )
  end

  def contact_params
    params.require(:contact).except(:comment).permit(
      :name, :email, :subject, :message
    )
  end

  def catch_spam
    return unless request.post? && params[:contact]
    return if params[:contact].fetch(:comment, '').blank?

    redirect_to frontpage_url
  end

  def set_recaptcha_required
    @recaptcha_required = AlaveteliConfiguration.contact_form_recaptcha
  end
end
