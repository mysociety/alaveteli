##
# Controller to allow Pro user to access past invoices.
#
class AlaveteliPro::InvoicesController < AlaveteliPro::BaseController
  def index
    @invoices = current_user.pro_account.invoices
  end
end
