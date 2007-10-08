# models/info_request.rb:
# A public body, from which information can be requested.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: public_body.rb,v 1.7 2007-10-08 14:51:47 francis Exp $

class PublicBody < ActiveRecord::Base
    validates_presence_of :request_email

    has_many :info_requests

    def validate
        unless MySociety::Validate.is_valid_email(request_email)
            errors.add(:request_email, "doesn't look like a valid email address")
        end
        if complaint_email != ""
            unless MySociety::Validate.is_valid_email(complaint_email)
                errors.add(:complaint_email, "doesn't look like a valid email address")
            end
        end
    end

    acts_as_versioned
    self.non_versioned_columns << 'created_at' << 'updated_at'
end
