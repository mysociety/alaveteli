# -*- encoding : utf-8 -*-
# app/controllers/admin_user_controller.rb:
# Controller for viewing user accounts from the admin interface.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminUserController < AdminController

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
        # Don't use @user as that is any logged in user
        @admin_user = User.find(params[:id])
    end

    def edit
        @admin_user = User.find(params[:id])
    end

    def update
        @admin_user = User.find(params[:id])

        @admin_user.name = params[:admin_user][:name]
        @admin_user.email = params[:admin_user][:email]
        @admin_user.admin_level = params[:admin_user][:admin_level]
        @admin_user.ban_text = params[:admin_user][:ban_text]
        @admin_user.about_me = params[:admin_user][:about_me]
        @admin_user.no_limit = params[:admin_user][:no_limit]
        @admin_user.can_make_batch_requests = params[:admin_user][:can_make_batch_requests]

        if @admin_user.valid?
            @admin_user.save!
            flash[:notice] = 'User successfully updated.'
            redirect_to admin_user_url(@admin_user)
        else
            render :action => 'edit'
        end
    end

    def banned
        @banned_users = User.paginate :order => "name", :page => params[:page], :per_page => 100,
            :conditions =>  ["ban_text <> ''"]
    end

    def show_bounce_message
        @admin_user = User.find(params[:id])
    end

    def clear_bounce
        user = User.find(params[:id])
        user.email_bounced_at = nil
        user.email_bounce_message = ""
        user.save!
        redirect_to admin_user_url(user)
    end

    def login_as
        @admin_user = User.find(params[:id]) # check user does exist

        post_redirect = PostRedirect.new( :uri => user_url(@admin_user), :user_id => @admin_user.id, :circumstance => "login_as" )
        post_redirect.save!
        url = confirm_url(:email_token => post_redirect.email_token)

        redirect_to url
    end

    def clear_profile_photo
        @admin_user = User.find(params[:id])

        if @admin_user.profile_photo
            @admin_user.profile_photo.destroy
        end

        flash[:notice] = "Profile photo cleared"
        redirect_to admin_user_url(@admin_user)
    end

    def modify_comment_visibility
        Comment.update_all(["visible = ?", !params[:hide_selected]], :id => params[:comment_ids])
        redirect_to :back
    end

    private

end
