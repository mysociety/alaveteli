# == Schema Information
# Schema version: 27
#
# Table name: post_redirects
#
#  id                 :integer         not null, primary key
#  token              :text            not null
#  uri                :text            not null
#  post_params_yaml   :text            
#  created_at         :datetime        not null
#  updated_at         :datetime        not null
#  email_token        :text            not null
#  reason_params_yaml :text            
#  user_id            :integer         
#

# models/post_redirect.rb:
# Saves an HTTP request, so it can be redirected to later.  For example, after
# registering / logging in. This can save POST requests, if post_params_yaml
# is not null.
#
# See check_in_post_redirect in controllers/application.rb for the hack that
# fakes the redirect to include POST parameters in request later.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: post_redirect.rb,v 1.14 2008-01-29 01:26:21 francis Exp $

require 'openssl' # for random bytes function

class PostRedirect < ActiveRecord::Base
    # Optional, does a login confirm before redirect for use in email links.
    belongs_to :user

    # We store YAML version of POST parameters in the database
    def post_params=(params)
        self.post_params_yaml = params.to_yaml
    end
    def post_params
        if self.post_params_yaml.nil?   
            return {}
        end
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

    # Used by (rspec) test code only
    def self.get_last_post_redirect
        # XXX yeuch - no other easy way of getting the token so we can check
        # the redirect URL, as it is by definition opaque to the controller
        # apart from in the place that it redirects to.
        post_redirects = PostRedirect.find_by_sql("select * from post_redirects order by id desc limit 1")
        post_redirects.size.should == 1
        return post_redirects[0]
    end

end



