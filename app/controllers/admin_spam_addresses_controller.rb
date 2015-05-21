# -*- encoding : utf-8 -*-
class AdminSpamAddressesController < AdminController
    before_filter :set_spam_address, :only => [:destroy]

    def index
        @spam_addresses = SpamAddress.all
        @spam_address = SpamAddress.new
    end

    def create
        @spam_address = SpamAddress.new(params[:spam_address])

        if @spam_address.save
            redirect_to admin_spam_addresses_path, :notice => "#{@spam_address.email} has been added to the spam addresses list"
        else
            @spam_addresses = SpamAddress.all
            render :index
        end
    end

    def destroy
        @spam_address.destroy
        redirect_to admin_spam_addresses_path, :notice => "#{@spam_address.email} has been removed from the spam addresses list"
    end

    private

    def set_spam_address
        @spam_address = SpamAddress.find(params[:id])
    end

end
