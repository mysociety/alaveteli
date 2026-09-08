##
# Controller responsible for serving the XML sitemap files.
#
# The files are built offline by `rake sitemap:generate` and written outside
# public/, so that ENABLE_SITEMAP can switch them off. A file in public/ is
# served by the webserver before the request reaches Rails, where no
# configuration could reach it.
#
class SitemapsController < ApplicationController
  skip_before_action :html_response

  before_action :check_sitemap_enabled

  def show
    raise RouteNotFound unless sitemap.exist?

    long_cache
    send_file sitemap, type: content_type, disposition: 'inline'
  end

  private

  def check_sitemap_enabled
    raise RouteNotFound unless Sitemap.enabled?
  end

  def sitemap
    @sitemap ||= Sitemap.path_for(params[:number])
  end

  def content_type
    params[:number].present? ? 'application/gzip' : 'application/xml'
  end
end
