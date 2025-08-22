# FOI officers can upload a response to an InfoRequest using a web UI
class UploadResponseController < RequestController
  read_only only: [:new]

  def new
    AlaveteliLocalization.with_locale(locale) do
      @info_request = InfoRequest.not_embargoed.find_by_url_title!(params[:url_title])

      @reason_params = {
        web: _('To upload a response, you must be logged in using an ' \
               'email address from {{authority_name}}',
               authority_name: CGI.escapeHTML(@info_request.public_body.name)),
        email: _('Then you can upload an FOI response. '),
        email_subject: _('Confirm your account on {{site_name}}',
                         site_name: site_name)
      }

      unless authenticated?
        ask_to_login(**@reason_params)
        return false
      end

      if @info_request.allow_new_responses_from == 'nobody'
        render template:
          'request/request_subtitle/allow_new_responses_from/_nobody'
        return
      end

      unless @info_request.public_body.is_foi_officer?(@user)
        domain_required = @info_request.public_body.foi_officer_domain_required

        if domain_required.nil?
          render template: 'user/wrong_user_unknown_email'
          return
        end

        @reason_params[:user_name] = "an email @" + domain_required

        render template: 'user/wrong_user'
        return
      end
    end

    if params[:submitted_upload_response]
      file_name = nil
      file_content = nil

      unless params[:file_1].nil?
        file_name = params[:file_1].original_filename
        file_content = params[:file_1].read
      end

      body = params[:body] || ""

      if file_name.nil? && body.empty?
        flash[:error] = _("Please type a message and/or choose a file " \
                            "containing your response.")
        return
      end

      mail = RequestMailer.fake_response(@info_request, @user, body, file_name, file_content)

      @info_request.
        receive(mail,
                mail.encoded,
                override_stop_new_responses: true)

      flash[:notice] = _("Thank you for responding to this FOI request! " \
                           "Your response has been published below, and a " \
                           "link to your response has been emailed to {{user_name}}.",
                         user_name: @info_request.user.name.html_safe)

      redirect_to request_url(@info_request)
      nil
    end
  end
end
