# app/controllers/request_game_controller.rb:
# The 'categorise old requests' game
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_game_controller.rb,v 1.3 2009-08-26 23:13:28 francis Exp $

class RequestGameController < ApplicationController
    
    def play
        if !authenticated?(
                :web => "To play the request categorisation game",
                :email => "Then you can play the request categorisation game.", 
                :email_subject => "Play the request categorisation game"
            )
            # do nothing - as "authenticated?" has done the redirect to signin page for us
            return
        end

        session[:request_game] = Time.now

        old = InfoRequest.find_old_unclassified(:conditions => ["prominence = 'normal'"], :age_in_days => 10)
        @missing = old.size
        @requests = old.sort_by{ rand }.slice(0..2)

        if @missing == 0
            flash[:notice] = 'All done! Thank you very much for your help.'
            redirect_to frontpage_url
        end
    end

    # Requests similar to this one
    def stop
        session[:request_game] = nil
        flash[:notice] = 'Thank you for helping us keep the site tidy!'
        redirect_to frontpage_url
    end

end

