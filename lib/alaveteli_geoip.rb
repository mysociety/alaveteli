# -*- encoding : utf-8 -*-
#
# Public: Class to handle getting an ISO 3166-1 alpha-2 country
# code from an IP address.  Prefer the class method
# country_code_from_ip rather than creating a
# new instance.

class AlaveteliGeoIP

  attr_reader :geoip, :gaze_url, :current_code

  # Public: Get the country code for a given IP address
  # Delegates to an instance configured with the geoip_database
  # See AlaveteliGeoIP#country_code_from_ip for more documentation.
  def self.country_code_from_ip(ip)
    instance.country_code_from_ip(ip)
  end

  def self.instance
    @instance ||= new
  end

  def initialize(database = nil)
    database = AlaveteliConfiguration::geoip_database unless database
    if database.present? && File.file?(database)
      @geoip = GeoIP.new(database)
    elsif AlaveteliConfiguration::gaze_url.present?
      @gaze_url = AlaveteliConfiguration::gaze_url
    end
    @current_code = AlaveteliConfiguration::iso_country_code
  end

  # Public: Return the country code of the country indicated by
  # the IP address
  #
  #  ip - String IP address
  #
  # Example
  #
  #    country_code_from_ip('64.233.161.99')
  #    # => "US"
  #
  # Returns a String
  def country_code_from_ip(ip)
    country_code =
      if geoip
        country_code_from_geoip(ip)
      elsif gaze_url
        country_code_from_gaze(ip)
      end
    country_code = current_code if country_code.blank?
    country_code
  end

  private

  def country_code_from_gaze(ip)
    quietly_try_to_open("#{gaze_url}/gaze-rest?f=get_country_from_ip;ip=#{ip}")
  end

  def country_code_from_geoip(ip)
    geoip.country(ip).country_code2
  end

end
