# -*- encoding : utf-8 -*-
# controllers/services_controller.rb:

require 'open-uri'

class ServicesController < ApplicationController

    def other_country_message
        flash.keep

        text = ""
        iso_country_code = AlaveteliConfiguration::iso_country_code.downcase
        if country_from_ip.downcase != iso_country_code
            found_country = WorldFOIWebsites.by_code(country_from_ip)

            old_fgt_locale = FastGettext.locale
            begin
              FastGettext.locale = FastGettext.best_locale_in(request.env['HTTP_ACCEPT_LANGUAGE'])
              if found_country && found_country[:country_name] && found_country[:url] && found_country[:name]
                  text = _("Hello! You can make Freedom of Information requests within {{country_name}} at {{link_to_website}}",
                    :country_name => found_country[:country_name], :link_to_website => "<a href=\"#{found_country[:url]}\">#{found_country[:name]}</a>".html_safe)
              else
                  country_data = WorldFOIWebsites.by_code(iso_country_code)
                  if country_data
                      text = _("Hello! We have an  <a href=\"{{url}}\">important message</a> for visitors outside {{country_name}}",
                                :country_name => country_data[:country_name],
                                :url => "/help/alaveteli?country_name=#{CGI.escape(country_data[:country_name])}")
                  else
                      text = _("Hello! We have an <a href=\"{{url}}\">important message</a> for visitors in other countries",
                                :url => "/help/alaveteli")
                  end
              end
            ensure
              FastGettext.locale = old_fgt_locale
            end
        end
        render :text => text, :content_type => "text/plain"  # TODO: workaround the HTML validation in test suite
    end

    def hidden_user_explanation
        info_request = InfoRequest.find(params[:info_request_id])
        render :template => "admin_request/hidden_user_explanation",
               :content_type => "text/plain",
               :layout => false,
               :locals => {:name_to => info_request.user_name,
                          :name_from => AlaveteliConfiguration::contact_name,
                          :info_request => info_request, :reason => params[:reason],
                          :info_request_url => 'http://' + AlaveteliConfiguration::domain + request_path(info_request),
                          :site_name => site_name}
    end

end
