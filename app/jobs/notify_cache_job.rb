require 'net/http'

class Net::HTTP::Purge < Net::HTTP::Get
  METHOD = 'PURGE'
end

class Net::HTTP::Ban < Net::HTTP::Get
  METHOD = 'BAN'
end

##
# Job to notify a cache of URLs to be purged or banned, given an object
# (that must have a cached_urls method).
#
# Examples:
#   NotifyCacheJob.perform(InfoRequest.first)
#   NotifyCacheJob.perform(FoiAttachment.first)
#   NotifyCacheJob.perform(Comment.first)
#
class NotifyCacheJob < ApplicationJob
  queue_as :default

  around_enqueue do |_, block|
    block.call if AlaveteliConfiguration.varnish_hosts.present?
  end

  def perform(object)
    urls = object.cached_urls
    locales = [''] + AlaveteliLocalization.available_locales.map { "/#{_1}" }
    hosts = AlaveteliConfiguration.varnish_hosts

    urls.product(locales, hosts).each do |url, locale, host|
      if url.start_with? '^'
        request = Net::HTTP::Ban.new('/')
        request['X-Invalidate-Pattern'] = '^' + locale + url[1..-1]
      else
        request = Net::HTTP::Purge.new(locale + url)
      end

      response = connection_for_host(host).request(request)
      log_result = "#{request.method} #{url} at #{host}: #{response.code}"

      case response
      when Net::HTTPSuccess
        Rails.logger.debug('NotifyCacheJob: ' + log_result)
      else
        Rails.logger.warn('NotifyCacheJob: Unable to ' + log_result)
      end
    end

  ensure
    close_connections
  end

  def connections
    @connections ||= {}
  end

  def connection_for_host(host)
    connections[host] ||= Net::HTTP.start(
      AlaveteliConfiguration.domain, 80, host, 6081
    )
  end

  def close_connections
    connections.values.each { _1.finish if _1.started? }
  end
end
