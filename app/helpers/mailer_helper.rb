# -*- encoding : utf-8 -*-
module MailerHelper
  def contact_from_name_and_email
    "#{AlaveteliConfiguration::contact_name} <#{AlaveteliConfiguration::contact_email}>"
  end

  def settings
      {
          :font_family => 'Helvetica, Arial, sans-serif',
          :content_width => 480,
          :button_background_color => '#d6eeff',
          :byline_color => '#666',
          :logo_url => 'logo.gif',
          :logo_width => 240,
          :logo_height => 30
      }
  end

  def style
      {
          :body => "font-family: #{settings[:font_family]}; margin: 0;",
          :table => "font-family: #{settings[:font_family]};",
          :td => "font-family: #{settings[:font_family]}; font-size: 16px; line-height: 24px;",
          :p => "font-family: #{settings[:font_family]}; font-size: 16px; line-height: 24px; margin: 0 0 1em 0;",
          :button => "display: inline-block; background-color: #{settings[:button_background_color]}; border: 10px solid #{settings[:button_background_color]}; border-width: 10px 15px; border-radius: 5px;",
          :logo => "display: block; margin-top: 1em;",
          :p_byline => "font-family: #{settings[:font_family]}; font-size: 16px; line-height: 24px; color: #{settings[:byline_color]};"
      }
  end
end
