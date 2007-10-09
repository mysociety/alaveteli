# app/controllers/user_controller.rb:
# Show information about a user.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user_controller.rb,v 1.2 2007-10-09 17:29:43 francis Exp $

class UserController < ApplicationController
    def index
        @display_users = User.find(:all, :conditions => [ "name = ?", params[:name] ])
    end

    private

end
