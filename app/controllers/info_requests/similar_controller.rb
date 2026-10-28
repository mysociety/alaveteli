##
# Controller to show requests similar to an InfoRequest
#
class InfoRequests::SimilarController < ApplicationController
  LIMIT = 25

  before_action :set_no_crawl_headers

  def index
    short_cache

    @info_request = InfoRequest.find_by_url_title!(params[:url_title])

    return render_hidden if cannot?(:read, @info_request)

    @results = @info_request.similar_requests.results(per_page: LIMIT)
  end
end
