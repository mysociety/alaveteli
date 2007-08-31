class PublicBody < ActiveRecord::Base
    validates_presence_of :request_email

    acts_as_versioned
end
