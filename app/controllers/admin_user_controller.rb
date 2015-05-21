# -*- encoding : utf-8 -*-
# app/controllers/admin_user_controller.rb:
# Controller for viewing user accounts from the admin interface.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminUserController < AdminController
    before_filter :set_user, :only => [:show, :edit, :update, :show_bounce_message, :clear_bounce, :login_as, :clear_profile_photo]

    def index
        @query = params[:query]
        if @query
            users = User.where(["lower(name) like lower('%'||?||'%') or
                                 lower(email) like lower('%'||?||'%')", @query, @query])
        else
            users = User
        end
        @admin_users = users.paginate :order => "name", :page => params[:page], :per_page => 100
    end

    def show
    end

    def edit
    end

    def update
        if @admin_user.update_attributes(user_params)
            redirect_to admin_user_url(@admin_user), :notice => 'User successfully updated.'
        else
            render :edit
        end
    end

    def banned
        @banned_users = User.paginate :order => "name", :page => params[:page], :per_page => 100,
            :conditions =>  ["ban_text <> ''"]
    end

    def show_bounce_message
    end

    def clear_bounce
        @admin_user.email_bounced_at = nil
        @admin_user.email_bounce_message = ""
        @admin_user.save!
        redirect_to admin_user_url(@admin_user)
    end

    def login_as
        post_redirect = PostRedirect.new( :uri => user_url(@admin_user), :user_id => @admin_user.id, :circumstance => "login_as" )
        post_redirect.save!
        redirect_to confirm_url(:email_token => post_redirect.email_token)
    end

    def clear_profile_photo
        if @admin_user.profile_photo
            @admin_user.profile_photo.destroy
        end
        redirect_to admin_user_url(@admin_user), :notice => "Profile photo cleared"
    end

    def modify_comment_visibility
        @visibility_value = params.key?(:hide_selected) ? false : true
        Comment.update_all(["visible=?", @visibility_value], :id => params[:comment_ids])
        redirect_to :back
    end

    private

    def set_user
        @admin_user = User.find(params[:id]) # Don't use @user as that is any logged in user
    end

    def user_params
        if params[:admin_user]
            params[:admin_user].slice(:name, :email, :admin_level, :ban_text, :about_me, :no_limit, :can_make_batch_requests)
        else
            {}
        end
    end

end
