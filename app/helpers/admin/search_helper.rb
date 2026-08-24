# Helpers for showing search stats in the admin interface
module Admin::SearchHelper
  def search_duration(seconds)
    ms = number_with_precision(seconds * 1000, precision: 1, delimiter: ',')
    "#{ms}ms"
  end

  def explain_search?
    params[:explain] == '1'
  end

  # The current listing, with the query plan switched on or off.
  def explain_search_url(explain)
    url_for(request.query_parameters.merge(explain: explain ? '1' : '0'))
  end
end
