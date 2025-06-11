class AdminInvalidReplyAddressesController < AdminController
  before_action :set_invalid_reply_address, only: [:destroy]

  def index
    @invalid_reply_addresses = InvalidReplyAddress.all
    @invalid_reply_address = InvalidReplyAddress.new
  end

  def create
    @invalid_reply_address = InvalidReplyAddress.new(invalid_reply_address_params)
    if @invalid_reply_address.save
      notice = "#{ @invalid_reply_address.email } has been added to the invalid reply addresses list"
      redirect_to admin_invalid_reply_addresses_path, notice: notice
    else
      @invalid_reply_addresses = InvalidReplyAddress.all
      render :index
    end
  end

  def destroy
    @invalid_reply_address.destroy
    notice = "#{ @invalid_reply_address.email } has been removed from the invalid reply addresses list"
    redirect_to admin_invalid_reply_addresses_path, notice: notice
  end

  private

  def invalid_reply_address_params
    if params[:invalid_reply_address]
      params.require(:invalid_reply_address).permit(:email)
    else
      {}
    end
  end

  def set_invalid_reply_address
    @invalid_reply_address = InvalidReplyAddress.find(params[:id])
  end
end