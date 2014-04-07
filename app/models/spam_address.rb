class SpamAddress < ActiveRecord::Base
    attr_accessible :email

    validates_presence_of :email, :message => _('Please enter the email address to mark as spam')
    validates_uniqueness_of :email, :message => _('This address is already marked as spam')

    def self.spam?(email_address)
        exists?(:email => email_address)
    end

end
