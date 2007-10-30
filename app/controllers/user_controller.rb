# app/controllers/user_controller.rb:
# Show information about a user.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user_controller.rb,v 1.4 2007-10-30 14:49:08 francis Exp $

class UserController < ApplicationController
    def show
        @display_users = User.find(:all, :conditions => [ "name = ?", params[:name] ], :order => "created_at desc")
    end

    private

end
