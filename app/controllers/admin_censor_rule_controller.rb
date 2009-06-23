# app/controllers/admin_censor_rule_controller.rb:
# For modifying requests.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_censor_rule_controller.rb,v 1.6 2009-06-23 13:52:25 francis Exp $

class AdminCensorRuleController < AdminController
    def new
        @info_request = InfoRequest.find(params[:info_request_id])
    end

    def create
        params[:censor_rule][:last_edit_editor] = admin_http_auth_user()
        @censor_rule = CensorRule.new(params[:censor_rule])
        expire_for_request(@censor_rule.info_request)
        if @censor_rule.save
            expire_for_request(@censor_rule.info_request)
            flash[:notice] = 'CensorRule was successfully created.'
            redirect_to admin_url('request/show/' + @censor_rule.info_request.id.to_s)
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
        # expire before and after change, in case filename changes
        expire_for_request(@censor_rule.info_request)
        if @censor_rule.update_attributes(params[:censor_rule])
            expire_for_request(@censor_rule.info_request)
            flash[:notice] = 'CensorRule was successfully updated.'
            redirect_to admin_url('request/show/' + @censor_rule.info_request.id.to_s)
        else
            render :action => 'edit'
        end
    end
    
    def destroy
        censor_rule = CensorRule.find(params[:censor_rule_id])
        info_request = censor_rule.info_request

        # expire before and after change, in case filename changes
        expire_for_request(info_request)
        censor_rule.destroy
        expire_for_request(info_request)

        flash[:notice] = "CensorRule was successfully destroyed."

        redirect_to admin_url('request/show/' + info_request.id.to_s)
    end

    private

end

