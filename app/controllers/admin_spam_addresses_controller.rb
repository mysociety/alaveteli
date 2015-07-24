# -*- encoding : utf-8 -*-
class AdminSpamAddressesController < AdminController

  def index
    @spam_addresses = SpamAddress.all
    @spam_address = SpamAddress.new
  end

  def create
    @spam_address = SpamAddress.new(params[:spam_address])

    if @spam_address.save
      notice = "#{ @spam_address.email } has been added to the spam addresses list"
      redirect_to admin_spam_addresses_path, :notice => notice
    else
      @spam_addresses = SpamAddress.all
      render :index
    end
  end

  def destroy
    @spam_address = SpamAddress.find(params[:id])
    @spam_address.destroy
    notice = "#{ @spam_address.email } has been removed from the spam addresses list"
    redirect_to admin_spam_addresses_path, :notice => notice
  end

end
