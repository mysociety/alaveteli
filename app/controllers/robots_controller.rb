##
# Controller responsible for rendering robots.txt.
#
# Serving this from a template rather than a static file in public/ means the
# crawl rules can reference configured values, and lets a theme override them
# without forking the file.
#
class RobotsController < ApplicationController
  skip_before_action :html_response

  def show
    long_cache

    render template: 'robots/show',
           formats: [:text],
           layout: false,
           content_type: 'text/plain'
  end
end
