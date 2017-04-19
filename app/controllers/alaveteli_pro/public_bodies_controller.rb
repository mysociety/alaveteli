class AlaveteliPro::PublicBodiesController < AlaveteliPro::BaseController
  def search
    query = params[:query] || ""
    xapian_results = perform_search_typeahead(query, PublicBody)
    results = xapian_results.present? ? xapian_results.results : []
    # Xapian's results include things we don't want to publish, like the
    # request email and api_key, so we map these results into a simpler object
    # with only some whitelisted attributes.
    results.map! do |result|
      body = result[:model]
      result = {
        id: body.id,
        name: body.name,
        short_name: body.short_name,
        notes: body.notes,
        info_requests_visible_count: body.info_requests_visible_count,
        weight: result[:weight],
      }
      # Render the result for the JS, so that we can use Rail's pluralisation,
      # translation, etc
      result[:html] = render_to_string(partial: 'alaveteli_pro/public_bodies/search_result',
                                       layout: false,
                                       locals: { result: result })
      result
    end

    render json: results
  end
end
