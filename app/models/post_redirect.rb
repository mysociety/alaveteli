# models/postredirect.rb:
# Saves an HTTP POST request, so it can be redirected to later.
# For example, after registering / logging in.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: post_redirect.rb,v 1.4 2007-11-06 15:58:56 francis Exp $

require 'openssl' # for random bytes function

class PostRedirect < ActiveRecord::Base
    # Optional, does a login confirm before redirect for use in email links.
    belongs_to :user

    # We store YAML version of POST parameters in the database
    def post_params=(params)
        self.post_params_yaml = params.to_yaml
    end
    def post_params
        YAML.load(self.post_params_yaml)
    end

    # We store YAML version of textual "reason for redirect" parameters
    def reason_params=(reason_params)
        self.reason_params_yaml = reason_params.to_yaml
    end
    def reason_params
        YAML.load(self.reason_params_yaml)
    end

    # Makes a random token, suitable for using in URLs e.g confirmation messages.
    def self.generate_random_token
        bits = 12 * 8
        # Make range from value to double value, so number of digits in base 36
        # encoding is quite long always.
        rand_num = rand(max = 2**(bits+1)) + 2**bits
        rand_num.to_s(base=36)
    end

    # Make the token 
    def after_initialize
        # The token is used to return you to what you are doing after the login form.
        if not self.token
            self.token = PostRedirect.generate_random_token
        end
        # There is a separate token to use in the URL if we send a confirmation email.
        # This is because 
        if not self.email_token
            self.email_token = PostRedirect.generate_random_token
        end
    end

end



