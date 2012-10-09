# app/controllers/admin_censor_rule_controller.rb:
# For modifying requests.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/

class AdminCensorRuleController < AdminController
    def new
        if params[:info_request_id]
            @info_request = InfoRequest.find(params[:info_request_id])
        end
        if params[:user_id]
            @user = User.find(params[:user_id])
        end
    end

    def create
        params[:censor_rule][:last_edit_editor] = admin_http_auth_user()
        @censor_rule = CensorRule.new(params[:censor_rule])
        if @censor_rule.save
            if !@censor_rule.info_request.nil?
                expire_for_request(@censor_rule.info_request)
            end
            if !@censor_rule.user.nil?
                expire_requests_for_user(@censor_rule.user)
            end
            flash[:notice] = 'CensorRule was successfully created.'
            if !@censor_rule.info_request.nil?
                redirect_to admin_url('request/show/' + @censor_rule.info_request.id.to_s)
            elsif !@censor_rule.user.nil?
                redirect_to admin_url('user/show/' + @censor_rule.user.id.to_s)
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
        params[:censor_rule][:last_edit_editor] = admin_http_auth_user()
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
                redirect_to admin_url('request/show/' + @censor_rule.info_request.id.to_s)
            elsif !@censor_rule.user.nil?
                redirect_to admin_url('user/show/' + @censor_rule.user.id.to_s)
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
            redirect_to admin_url('request/show/' + info_request.id.to_s)
        elsif !user.nil?
            redirect_to admin_url('user/show/' + user.id.to_s)
        else
            raise "internal error"
        end
     end

    private

end

