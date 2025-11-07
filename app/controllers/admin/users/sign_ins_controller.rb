# Display information about User::SignIn attempts
class Admin::Users::SignInsController < AdminController
  layout 'admin/users'

  def index
    @title = 'Listing user sign ins'

    @query = params[:query]

    sign_ins = User::SignIn
    sign_ins = sign_ins.search(@query) if @query

    @sign_ins = sign_ins.paginate(page: params[:page], per_page: 100)
  end
end
