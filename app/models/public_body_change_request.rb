# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: public_body_change_requests
#
#  id                :integer          not null, primary key
#  user_email        :string(255)
#  user_name         :string(255)
#  user_id           :integer
#  public_body_name  :text
#  public_body_id    :integer
#  public_body_email :string(255)
#  source_url        :text
#  notes             :text
#  is_open           :boolean          default(TRUE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class PublicBodyChangeRequest < ActiveRecord::Base

    belongs_to :user
    belongs_to :public_body
    validates_presence_of :public_body_name, :message => N_("Please enter the name of the authority"),
                                             :unless => proc{ |change_request| change_request.public_body }
    validates_presence_of :user_name, :message => N_("Please enter your name"),
                                      :unless => proc{ |change_request| change_request.user }
    validates_presence_of :user_email, :message => N_("Please enter your email address"),
                                      :unless => proc{ |change_request| change_request.user }
    validate :user_email_format, :unless => proc{ |change_request| change_request.user_email.blank? }
    validate :body_email_format, :unless => proc{ |change_request| change_request.public_body_email.blank? }

    scope :new_body_requests, :conditions => ['public_body_id IS NULL'], :order => 'created_at'
    scope :body_update_requests, :conditions => ['public_body_id IS NOT NULL'], :order => 'created_at'
    scope :open, :conditions => ['is_open = ?', true]

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

    def get_user_name
        user ? user.name : user_name
    end

    def get_user_email
        user ? user.email : user_email
    end

    def get_public_body_name
        public_body ? public_body.name : public_body_name
    end

    def send_message
        if public_body
            ContactMailer.update_public_body_email(self).deliver
        else
            ContactMailer.add_public_body(self).deliver
        end
    end

    def thanks_notice
        if self.public_body
            _("Your request to update the address for {{public_body_name}} has been sent. Thank you for getting in touch! We'll get back to you soon.",
              :public_body_name => get_public_body_name)
        else
            _("Your request to add an authority has been sent. Thank you for getting in touch! We'll get back to you soon.")
        end
    end

    def send_response(subject, response)
        ContactMailer.from_admin_message(get_user_name,
                                         get_user_email,
                                         subject,
                                         response.strip.html_safe).deliver
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

    def default_response_subject
        if self.public_body
            _("Your request to update {{public_body_name}} on {{site_name}}", :site_name => AlaveteliConfiguration::site_name,
                                                                       :public_body_name => public_body.name)
        else
            _("Your request to add {{public_body_name}} to {{site_name}}", :site_name => AlaveteliConfiguration::site_name,
                                                                       :public_body_name => public_body_name)
        end
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
