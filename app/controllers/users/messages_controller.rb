# -*- encoding : utf-8 -*-
# Allowing users to send user-to-user messages
class Users::MessagesController < UserController

  before_action :set_recipient, :set_recaptcha_required

  # Send a message to another user
  def contact
    # Banned from messaging users?
    if authenticated_user && !authenticated_user.can_contact_other_users?
      @details = authenticated_user.can_fail_html
      render :template => 'user/banned'
      return
    end

    # You *must* be logged into send a message to another user. (This is
    # partly to avoid spam, and partly to have some equanimity of openess
    # between the two users)
    #
    # "authenticated?" has done the redirect to signin page for us
    return unless authenticated?(
        :web => _("To send a message to {{user_name}}",
                  :user_name => CGI.escapeHTML(@recipient_user.name)),
        :email => _("Then you can send a message to {{user_name}}.",
                    :user_name => @recipient_user.name),
        :email_subject => _("Send a message to {{user_name}}",
                            :user_name => @recipient_user.name)
      )

    if params[:submitted_contact_form]
      if @recaptcha_required && !verify_recaptcha
        flash.now[:error] = _('There was an error with the reCAPTCHA. ' \
                              'Please try again.')
      else
        params[:contact][:name] = @user.name
        params[:contact][:email] = @user.email
        @contact = ContactValidator.new(params[:contact])
        if @contact.valid?
          ContactMailer.user_message(
            @user,
            @recipient_user,
            user_url(@user),
            params[:contact][:subject],
            params[:contact][:message]
          ).deliver_now
          flash[:notice] = _("Your message to {{recipient_user_name}} has " \
                             "been sent!",
                             :recipient_user_name => @recipient_user.
                                                       name.html_safe)
          redirect_to user_url(@recipient_user)
        end
      end
      return
    else
      @contact = ContactValidator.new(
        { :message => "" + @recipient_user.name + _(",\n\n\n\nYours,\n\n{{user_name}}",:user_name=>@user.name) }
      )
    end

  end

  private

  def set_recipient
    @recipient_user = User.find(params[:id])
  end

  def set_recaptcha_required
    @recaptcha_required = AlaveteliConfiguration.user_contact_form_recaptcha
  end

end
