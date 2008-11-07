# app/controllers/help_controller.rb:
# Show information about one particular request.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: help_controller.rb,v 1.10 2008-11-07 00:01:49 francis Exp $

class HelpController < ApplicationController
    
    def about
    end

    def unhappy
        @info_request = nil
        if params[:url_title]
            @info_request = InfoRequest.find_by_url_title(params[:url_title])
        end
    end

    def contact
        @contact_email = MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost')
        @contact_email = @contact_email.gsub(/@/, "&#64;")

        # if they clicked remove for link to request/body, remove it
        if params[:remove]
            @last_request = nil
            session[:last_request_id] = nil
            session[:last_body_id] = nil
        end

        # look up link to request/body
        @last_request_id = session[:last_request_id].to_i
        if @last_request_id > 0
            @last_request = InfoRequest.find(@last_request_id)
        else
            @last_request = nil
        end
        @last_body_id = session[:last_body_id].to_i
        if @last_body_id > 0
            @last_body = PublicBody.find(@last_body_id)
        else
            @last_body = nil
        end

        # submit form
        if params[:submitted_contact_form]
            if @user
                params[:contact][:email] = @user.email
                params[:contact][:name] = @user.name
            end
            @contact = ContactValidator.new(params[:contact])
            if @contact.valid? && !params[:remove]
                ContactMailer.deliver_message(
                    params[:contact][:name],
                    params[:contact][:email],
                    params[:contact][:subject],
                    params[:contact][:message],
                    @user,
                    @last_request, @last_body
                )
                flash[:notice] = "Your message has been sent. Thank you for getting in touch! We'll get back to you soon."
                redirect_to frontpage_url 
                return
            end

            if params[:remove]
                @contact.errors.clear
            end
        end
         
    end

end
