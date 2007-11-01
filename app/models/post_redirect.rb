# models/postredirect.rb:
# Saves an HTTP POST request, so it can be redirected to later.
# For example, after registering / logging in.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: post_redirect.rb,v 1.1 2007-11-01 14:45:56 francis Exp $

require 'openssl' # for random bytes function

class PostRedirect < ActiveRecord::Base
    # We store YAML version of POST parameters in the database
    def post_params=(params)
        self.post_params_yaml = params.to_yaml
    end
    def post_params
        YAML.load(self.post_params_yaml)
    end

    # Make the token 
    def after_initialize
        if not self.token
            bytes = OpenSSL::Random.random_bytes(12)
            # XXX Ruby has some base function that can do base 62 or 32 more easily?
            base64 = [bytes].pack("m9999").strip
            base64.gsub("+", "a")
            base64.gsub("/", "b")
            base64.gsub("=", "c")
            self.token = base64
        end
    end

end


