# == Schema Information
# Schema version: 20220210114052
#
# Table name: public_body_change_requests
#
#  id                :integer          not null, primary key
#  user_email        :string
#  user_name         :string
#  user_id           :integer
#  public_body_name  :text
#  public_body_id    :integer
#  public_body_email :string
#  source_url        :text
#  notes             :text
#  is_open           :boolean          default(TRUE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class PublicBodyChangeRequest < ApplicationRecord
  belongs_to :user,
             :inverse_of => :public_body_change_requests,
             :counter_cache => true
  belongs_to :public_body,
             :inverse_of => :public_body_change_requests

  validates_presence_of :public_body_name,
                        :message => N_("Please enter the name of the authority"),
                        :unless => proc { |change_request| change_request.public_body }
  validates_presence_of :user_name,
                        :message => N_("Please enter your name"),
                        :unless => proc { |change_request| change_request.user }
  validates_presence_of :user_email,
                        :message => N_("Please enter your email address"),
                        :unless => proc { |change_request| change_request.user }
  validate :user_email_format, :unless => proc { |change_request| change_request.user_email.blank? }
  validate :body_email_format, :unless => proc { |change_request| change_request.public_body_email.blank? }

  scope :new_body_requests, -> {
    where(public_body_id: nil).order("created_at")
  }
  scope :body_update_requests, -> {
    where("public_body_id IS NOT NULL").order("created_at")
  }

  singleton_class.undef_method :open # Undefine Kernel.open to avoid warning
  scope :open, -> { where(is_open: true) }

  def self.from_params(params, user)
    change_request = new
    change_request.update_from_params(params, user)
  end

  def update_from_params(params, user)
    if user
      self.user_id = user.id
    else
      self.user_name = params[:user_name]
      self.user_email = params[:user_email]
    end
    self.public_body_name = params[:public_body_name]
    self.public_body_id = params[:public_body_id]
    self.public_body_email = params[:public_body_email]
    self.source_url = params[:source_url]
    self.notes = params[:notes]
    self
  end

  def add_body_request?
    public_body ? false : true
  end

  def get_user_name
    user ? user.name : user_name
  end

  def get_user_email
    user ? user.email : user_email
  end

  def get_public_body_name
    public_body ? public_body.name : public_body_name
  end

  def current_public_body_email
    public_body&.request_email
  end

  def send_message
    mail =
      if add_body_request?
        PublicBodyChangeRequestMailer.add_public_body(self)
      else
        PublicBodyChangeRequestMailer.update_public_body(self)
      end

    mail.deliver_now
  end

  def thanks_notice
    if add_body_request?
      _("Your request to add an authority has been sent. Thank you for " \
        "getting in touch! We'll get back to you soon.")
    else
      _("Your request to update the address for {{public_body_name}} has " \
        "been sent. Thank you for getting in touch! We'll get back to you " \
        "soon.",
        :public_body_name => get_public_body_name)
    end
  end

  def send_response(subject, response)
    ContactMailer.from_admin_message(get_user_name,
                                     get_user_email,
                                     subject,
                                     response.strip.html_safe).deliver_now
  end

  def comment_for_public_body
    comments = ["Requested by: #{get_user_name} (#{get_user_email})"]
    if !source_url.blank?
      comments << "Source URL: #{source_url}"
    end
    if !notes.blank?
      comments << "Notes: #{notes}"
    end
    comments.join("\n")
  end

  def request_subject
    if add_body_request?
      _("Add authority - {{public_body_name}}",
        :public_body_name => public_body_name.html_safe).to_str
    else
      _("Update email address - {{public_body_name}}",
        :public_body_name => public_body.name.html_safe).to_str
    end
  end

  def default_response_subject
    "Re: #{request_subject}"
  end

  def close!
    self.is_open = false
    self.save!
  end

  private

  def body_email_format
    unless MySociety::Validate.is_valid_email(self.public_body_email)
      errors.add(:public_body_email, _("The authority email doesn't look like a valid address"))
    end
  end

  def user_email_format
    unless MySociety::Validate.is_valid_email(self.user_email)
      errors.add(:user_email, _("Your email doesn't look like a valid address"))
    end
  end
end
