# app/controllers/admin_censor_rule_controller.rb:
# For modifying requests.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminCensorRuleController < AdminController
    def new
        if params[:info_request_id]
            @info_request = InfoRequest.find(params[:info_request_id])
            @censor_rule = @info_request.censor_rules.build
            @form_url = admin_info_request_censor_rules_path(@info_request)
        end

        if params[:user_id]
            @censor_user = User.find(params[:user_id])
            @censor_rule = @censor_user.censor_rules.build
            @form_url = admin_user_censor_rules_path(@censor_user)
        end

        @censor_rule ||= CensorRule.new
        @form_url ||= admin_rule_create_path
    end

    def create
        params[:censor_rule][:last_edit_editor] = admin_current_user

        if params[:info_request_id]
            @info_request = InfoRequest.find(params[:info_request_id])
            @censor_rule = @info_request.censor_rules.build(params[:censor_rule])
        end

        if params[:user_id]
            @censor_user = User.find(params[:user_id])
            @censor_rule = @censor_user.censor_rules.build(params[:censor_rule])
        end

        @censor_rule ||= CensorRule.new(params[:censor_rule])

        if @censor_rule.save
            if !@censor_rule.info_request.nil?
                expire_for_request(@censor_rule.info_request)
            end

            if !@censor_rule.user.nil?
                expire_requests_for_user(@censor_rule.user)
            end

            flash[:notice] = 'CensorRule was successfully created.'

            if !@censor_rule.info_request.nil?
                redirect_to admin_request_show_url(@censor_rule.info_request)
            elsif !@censor_rule.user.nil?
                redirect_to admin_user_show_url(@censor_rule.user)
            else
                raise "internal error"
            end
        else
            render :action => 'new'
        end
    end

    def edit
        @censor_rule = CensorRule.find(params[:id])
    end

    def update
        params[:censor_rule][:last_edit_editor] = admin_current_user()
        @censor_rule = CensorRule.find(params[:id])
        if @censor_rule.update_attributes(params[:censor_rule])
            if !@censor_rule.info_request.nil?
                expire_for_request(@censor_rule.info_request)
            end
            if !@censor_rule.user.nil?
                expire_requests_for_user(@censor_rule.user)
            end
            flash[:notice] = 'CensorRule was successfully updated.'
            if !@censor_rule.info_request.nil?
                redirect_to admin_request_show_url(@censor_rule.info_request)
            elsif !@censor_rule.user.nil?
                redirect_to admin_user_show_url(@censor_rule.user)
            else
                raise "internal error"
            end
        else
            render :action => 'edit'
        end
    end

    def destroy
        censor_rule = CensorRule.find(params[:censor_rule_id])
        info_request = censor_rule.info_request
        user = censor_rule.user

        censor_rule.destroy
        if !info_request.nil?
            expire_for_request(info_request)
        end
        if !user.nil?
            expire_requests_for_user(user)
        end

        flash[:notice] = "CensorRule was successfully destroyed."
        if !info_request.nil?
            redirect_to admin_request_show_url(info_request)
        elsif !user.nil?
            redirect_to admin_user_show_url(user)
        else
            raise "internal error"
        end
     end

    private

end

