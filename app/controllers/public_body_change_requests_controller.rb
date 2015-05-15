# -*- encoding : utf-8 -*-
class PublicBodyChangeRequestsController < ApplicationController

    before_filter :catch_spam, :only => [:create]

    def create
        @change_request = PublicBodyChangeRequest.from_params(params[:public_body_change_request], @user)
        if @change_request.save
            @change_request.send_message
            flash[:notice] = @change_request.thanks_notice
            redirect_to frontpage_url
            return
        else
            render :action => 'new'
        end
    end

    def new
        @change_request = PublicBodyChangeRequest.new
        if params[:body]
            @change_request.public_body = PublicBody.find_by_url_name_with_historic(params[:body])
        end
        if @change_request.public_body
            @title = _('Ask us to update the email address for {{public_body_name}}',
                            :public_body_name => @change_request.public_body.name)
        else
            @title = _('Ask us to add an authority')
        end
    end

    private

    def catch_spam
        if params[:public_body_change_request].key?(:comment)
            unless params[:public_body_change_request][:comment].empty?
                redirect_to frontpage_url
            end
        end
    end

end
