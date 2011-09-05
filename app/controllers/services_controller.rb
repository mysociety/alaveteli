# controllers/application.rb:
# Parent class of all controllers in FOI site. Filters added to this controller
# apply to all controllers in the application. Likewise, all the methods added
# will be available for all controllers.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: application.rb,v 1.59 2009-09-17 13:01:56 francis Exp $

require 'open-uri'

class ServicesController < ApplicationController
    def other_country_message
        text = ""
        iso_country_code = MySociety::Config.get('ISO_COUNTRY_CODE').downcase
        if country_from_ip.downcase != iso_country_code
            found_country = WorldFOIWebsites.by_code(country_from_ip)
            found_country_name = !found_country.nil? && found_country[:country_name]
            if found_country_name
                text = _("Hello! You can make Freedom of Information requests within {{country_name}} at {{link_to_website}}", :country_name => found_country_name, :link_to_website => "<a href=\"#{found_country[:url]}\">#{found_country[:name]}</a>")
            else
                current_country = WorldFOIWebsites.by_code(iso_country_code)[:country_name]
                text = _("Hello! We have an  <a href=\"/help/alaveteli?country_name=#{CGI.escape(current_country)}\">important message</a> for visitors outside {{country_name}}", :country_name => current_country)
            end
        end
        if !text.empty?
            text += ' <span class="close-button">X</span>'
        end
        render :text => text, :content_type => "text/plain"  # XXX workaround the HTML validation in test suite
    end
end
