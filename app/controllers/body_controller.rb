# app/controllers/body_controller.rb:
# Show information about a public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: body_controller.rb,v 1.1 2007-10-11 22:01:36 francis Exp $

class BodyController < ApplicationController
    def show
        @public_bodies = PublicBody.find(:all, :conditions => [ "short_name = ?", params[:short_name] ])
        if @public_bodies.size > 1
            raise "Two bodies with the same short name: " . params[:short_name]
        end
        @public_body = @public_bodies[0]
    end

end
