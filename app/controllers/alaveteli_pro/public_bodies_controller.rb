# -*- encoding : utf-8 -*-
class AlaveteliPro::PublicBodiesController < AlaveteliPro::BaseController
  def search
    query = params[:query] || ""
    xapian_results = typeahead_search(query, :model => PublicBody,
                                             :exclude_tags => [ 'defunct',
                                                                'not_apply' ])
    results = xapian_results.present? ? xapian_results.results : []
    # Exclude any bodies we can't make a request to (in addition to the ones
    # we've already filtered out by the excluded tags above)
    results.select! { |result| result[:model].is_requestable? }
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
        about: _('About {{public_body_name}}', public_body_name: body.name)
      }
      # Render the result for the JS, so that we can use Rail's pluralisation,
      # translation, etc
      result[:html] = render_to_string(
        partial: 'alaveteli_pro/public_bodies/search_result',
        layout: false,
        locals: { result: result }
      )
      result
    end

    render json: results
  end
end
