# -*- encoding : utf-8 -*-
#
# Public: Class to handle getting an ISO 3166-1 alpha-2 country
# code from an IP address.  Prefer the class method
# country_code_from_ip rather than creating a
# new instance.

class AlaveteliGeoIP
  require 'maxmind/db'

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
      @geoip = MaxMind::DB.new(database, mode: MaxMind::DB::MODE_MEMORY)
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

    if country_code.blank?
      current_code
    else
      country_code
    end
  end

  private

  def country_code_from_gaze(ip)
    quietly_try_to_open("#{gaze_url}/gaze-rest?f=get_country_from_ip;ip=#{ip}")
  end

  def country_code_from_geoip(ip)
    record = geoip.get(ip)
    record = record['country'] || record['continent'] if record

    return unless record

    iso_code(record)
  end

  def iso_code(geoip_data)
    geoip_data['iso_code']
  end
end
