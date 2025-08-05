# -*- encoding : utf-8 -*-
class AlaveteliPro::PublicBodiesController < AlaveteliPro::BaseController
  include AlaveteliPro::PublicBodiesHelper

  def index
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
      public_body_search_attributes(result[:model])
        .merge(weight: result[:weight])
    end

    render json: results
  end
end
