# -*- encoding : utf-8 -*-
def theme_url_to_theme_name(theme_url)
  File.basename theme_url, '.git'
end
