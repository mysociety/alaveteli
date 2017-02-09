class AlaveteliPro::PublicBodiesController < AlaveteliPro::BaseController
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper

  def search
    query = params[:query] || ""
    xapian_results = perform_search_typeahead(query, PublicBody)
    results = xapian_results.present? ? xapian_results.results : []
    # Xapian's results include things we don't want to publish, like the
    # request email and api_key, so we map these results into a simpler object
    # with only some whitelisted attributes.
    results.map! do |result|
      body = result[:model]
      {
        id: body.id,
        name: body.name,
        notes: truncate(strip_tags(body.notes), length: 150),
        info_requests_visible_count: body.info_requests_visible_count,
        weight: result[:weight]
      }
    end
    render json: results
  end
end
