class SessionsController < ApplicationController

    def destroy
        session[:user_id] = nil
        session[:user_circumstance] = nil
        session[:remember_me] = false
        session[:using_admin] = nil
        session[:admin_name] = nil

        if params[:r]
            redirect_to params[:r]
        else
            redirect_to frontpage_path
        end

    end

end
