# controllers/services_controller.rb:

require 'open-uri'

class ServicesController < ApplicationController

    def other_country_message
        text = ""
        iso_country_code = Configuration::iso_country_code.downcase
        if country_from_ip.downcase != iso_country_code
            found_country = WorldFOIWebsites.by_code(country_from_ip)

            old_fgt_locale = FastGettext.locale
            begin
              FastGettext.locale = FastGettext.best_locale_in(request.env['HTTP_ACCEPT_LANGUAGE'])
              if found_country && found_country[:country_name] && found_country[:url] && found_country[:name]
                  text = _("Hello! You can make Freedom of Information requests within {{country_name}} at {{link_to_website}}",
                    :country_name => found_country[:country_name], :link_to_website => "<a href=\"#{found_country[:url]}\">#{found_country[:name]}</a>".html_safe)
              else
                  current_country = WorldFOIWebsites.by_code(iso_country_code)[:country_name]
                  text = _("Hello! We have an  <a href=\"/help/alaveteli?country_name=#{CGI.escape(current_country)}\">important message</a> for visitors outside {{country_name}}", :country_name => current_country)
              end
            ensure
              FastGettext.locale = old_fgt_locale
            end
        end
        if !text.empty?
            text += ' <span class="close-button">X</span>'.html_safe
        end
        render :text => text, :content_type => "text/plain"  # XXX workaround the HTML validation in test suite
    end

    def hidden_user_explanation
        info_request = InfoRequest.find(params[:info_request_id])
        render :template => "admin_request/hidden_user_explanation",
               :content_type => "text/plain",
               :layout => false,
               :locals => {:name_to => info_request.user_name,
                          :name_from => Configuration::contact_name,
                          :info_request => info_request, :reason => params[:reason],
                          :info_request_url => 'http://' + Configuration::domain + request_path(info_request),
                          :site_name => site_name}
    end

end
