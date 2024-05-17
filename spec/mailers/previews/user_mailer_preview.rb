class UserMailerPreview < ActionMailer::Preview
  def confirm_login
    UserMailer.confirm_login(user, reasons, url)
  end

  def already_registered
    UserMailer.already_registered(user, reasons, url)
  end

  def changeemail_confirm
    UserMailer.changeemail_confirm(user, 'new@localhost', url)
  end

  def changeemail_already_used
    UserMailer.changeemail_already_used(user.email, 'new@localhost')
  end

  private

  def user
    User.first
  end

  def reasons
    {
      email: _('Then your FOI request to {{public_body_name}} will be sent ' \
               'and published.',
               public_body_name: public_body.name),
      email_subject: _('Confirm your FOI request to {{public_body_name}}',
                       public_body_name: public_body.name)
    }
  end

  def url
    'http:///www.example.org/c/ABC'
  end

  def public_body
    PublicBody.first
  end
end
