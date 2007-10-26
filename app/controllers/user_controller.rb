# app/controllers/user_controller.rb:
# Show information about a user.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user_controller.rb,v 1.3 2007-10-26 18:00:26 francis Exp $

class UserController < ApplicationController
    def index
        @display_users = User.find(:all, :conditions => [ "name = ?", params[:name] ], :order => "created_at desc")
    end

    private

end
