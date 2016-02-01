# -*- encoding : utf-8 -*-
# controllers/services_controller.rb:

require 'open-uri'

class ServicesController < ApplicationController

  def other_country_message
    flash.keep

    text = ""
    site_country_code = AlaveteliConfiguration.iso_country_code.downcase
    user_country_code = country_from_ip.downcase

    if user_country_code != site_country_code
      user_site = WorldFOIWebsites.by_code(user_country_code)
      old_fgt_locale = FastGettext.locale

      begin
        FastGettext.locale = FastGettext.best_locale_in(request.env['HTTP_ACCEPT_LANGUAGE'])

        if user_site && user_site[:country_name] && user_site[:url] && user_site[:name]
          country_site = user_site[:name]
          country_name = user_site[:country_name]
          country_code = user_site[:country_iso_code]
          country_url = user_site[:url]
          country_link = %Q(<a href="#{ country_url }">#{ country_site }</a>)

          text = if WorldFOIWebsites.can_ask_the_eu?(country_code)
            asktheeu_link = %q(<a href="http://asktheeu.org">Ask The EU</a>)

            _("Hello! You can make Freedom of Information requests within " \
              "{{country_name}} at {{link_to_website}} and to EU " \
              "institutions at {{link_to_asktheeu}}",
              :country_name => country_name,
              :link_to_website => country_link.html_safe,
              :link_to_asktheeu => asktheeu_link.html_safe)
          else
            _("Hello! You can make Freedom of Information requests within " \
              "{{country_name}} at {{link_to_website}}",
              :country_name => country_name,
              :link_to_website => country_link.html_safe)
          end
        else
          country_data = WorldFOIWebsites.by_code(site_country_code)
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

    # TODO: workaround the HTML validation in test suite
    render :text => text, :content_type => "text/plain"
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
