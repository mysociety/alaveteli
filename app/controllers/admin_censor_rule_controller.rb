# app/controllers/admin_censor_rule_controller.rb:
# For modifying requests.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminCensorRuleController < AdminController

    before_filter :set_editor, :only => [:create, :update]

    def new
        if params[:request_id]
            @info_request = InfoRequest.find(params[:request_id])
            @censor_rule = @info_request.censor_rules.build
            @form_url = admin_request_censor_rules_path(@info_request)
        end

        if params[:user_id]
            @censor_user = User.find(params[:user_id])
            @censor_rule = @censor_user.censor_rules.build
            @form_url = admin_user_censor_rules_path(@censor_user)
        end
    end

    def create
        if params[:request_id]
            @info_request = InfoRequest.find(params[:request_id])
            @censor_rule = @info_request.censor_rules.build(params[:censor_rule])
            @form_url = admin_request_censor_rules_path(@info_request)
        end

        if params[:user_id]
            @censor_user = User.find(params[:user_id])
            @censor_rule = @censor_user.censor_rules.build(params[:censor_rule])
            @form_url = admin_user_censor_rules_path(@censor_user)
        end

        if @censor_rule.save

            flash[:notice] = 'CensorRule was successfully created.'

            if @censor_rule.info_request
                expire_for_request(@censor_rule.info_request)
                redirect_to admin_request_url(@censor_rule.info_request)
            elsif @censor_rule.user
                expire_requests_for_user(@censor_rule.user)
                redirect_to admin_user_url(@censor_rule.user)
            end
        else
            render :action => 'new'
        end
    end

    def edit
        @censor_rule = CensorRule.find(params[:id])
    end

    def update
        @censor_rule = CensorRule.find(params[:id])

        if @censor_rule.update_attributes(params[:censor_rule])

            flash[:notice] = 'CensorRule was successfully updated.'

            if @censor_rule.info_request
                expire_for_request(@censor_rule.info_request)
                redirect_to admin_request_url(@censor_rule.info_request)
            elsif @censor_rule.user
                expire_requests_for_user(@censor_rule.user)
                redirect_to admin_user_url(@censor_rule.user)
            else
                raise "internal error"
            end

        else
            render :action => 'edit'
        end
    end

    def destroy
        @censor_rule = CensorRule.find(params[:id])
        info_request = @censor_rule.info_request
        user = @censor_rule.user

        @censor_rule.destroy

        flash[:notice] = "CensorRule was successfully destroyed."

        if info_request
            expire_for_request(info_request)
            redirect_to admin_request_url(info_request)
        elsif user
            expire_requests_for_user(user) if user
            redirect_to admin_user_url(user)
        else
            raise "internal error"
        end

     end

    private

    def set_editor
        params[:censor_rule][:last_edit_editor] = admin_current_user
    end
end

