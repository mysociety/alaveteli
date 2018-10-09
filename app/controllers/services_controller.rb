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
      old_fgt_locale = AlaveteliLocalization.locale

      begin
        AlaveteliLocalization.
          set_session_locale(request.env['HTTP_ACCEPT_LANGUAGE'])

        if user_site
          country_link = %Q(<a href="#{ user_site[:url] }">#{ user_site[:name] }</a>)

          text = if WorldFOIWebsites.can_ask_the_eu?(user_site[:country_iso_code])
            user_site_and_eu_site_msg(user_site[:country_name], country_link)
          else
            user_site_msg(user_site[:country_name], country_link)
          end
        else
          country_data = WorldFOIWebsites.by_code(site_country_code)


          text = if WorldFOIWebsites.can_ask_the_eu?(user_country_code)
            if country_data
              no_user_site_eu_msg(country_data[:country_name])
            else
              no_user_site_eu_msg
            end
          elsif country_data
            no_user_site_msg(country_data[:country_name])
          else
            no_user_site_msg
          end
        end
      ensure
        AlaveteliLocalization.set_session_locale(old_fgt_locale)
      end
    end

    # TODO: workaround the HTML validation in test suite
    render :plain => text
  end

  def hidden_user_explanation
    info_request = InfoRequest.find(params[:info_request_id])
    render template: "admin_request/hidden_user_explanation",
           formats: [:text],
           layout: false,
           locals: {
             name_to: info_request.user_name.html_safe,
             info_request: info_request,
             reason: params[:reason],
             info_request_url: request_url(info_request),
             site_name: site_name.html_safe }
  end

  private

  def user_site_and_eu_site_msg(country_name, country_link)
    _("Hello! You can make Freedom of Information requests within " \
      "{{country_name}} at {{link_to_website}} and to EU " \
      "institutions at {{link_to_asktheeu}}",
      :country_name => country_name,
      :link_to_website => country_link.html_safe,
      :link_to_asktheeu => ask_the_eu_link.html_safe)
  end

  def user_site_msg(country_name, country_link)
    _("Hello! You can make Freedom of Information requests within " \
      "{{country_name}} at {{link_to_website}}",
      :country_name => country_name,
      :link_to_website => country_link.html_safe)
  end

  def no_user_site_msg(country_name = nil)
    if country_name
      _("Hello! We have an  <a href=\"{{url}}\">important message</a> for visitors outside {{country_name}}",
        :country_name => country_name,
        :url => "/help/alaveteli?country_name=#{CGI.escape(country_name)}")
    else
      _("Hello! We have an <a href=\"{{url}}\">important message</a> for visitors in other countries",
        :url => "/help/alaveteli")
    end
  end

  def no_user_site_eu_msg(country_name = nil)
    if country_name
      _("Hello! We have an <a href=\"{{url}}\">important message</a> for " \
        "visitors outside {{country_name}}. You can also make Freedom of " \
        "Information requests to EU institutions at {{link_to_asktheeu}}",
        :country_name => country_name,
        :url => "/help/alaveteli?country_name=#{CGI.escape(country_name)}",
        :link_to_asktheeu => ask_the_eu_link.html_safe)
    else
      _("Hello! We have an <a href=\"{{url}}\">important message</a> for " \
        "visitors in other countries. You can also make Freedom of " \
        "Information requests to EU institutions at {{link_to_asktheeu}}",
        :url => "/help/alaveteli",
        :link_to_asktheeu => ask_the_eu_link.html_safe)
    end
  end

  def ask_the_eu_link
    %q(<a href="http://asktheeu.org">Ask The EU</a>)
  end

end
