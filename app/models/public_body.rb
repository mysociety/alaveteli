class PublicBody < ActiveRecord::Base
    validates_presence_of :request_email

end
