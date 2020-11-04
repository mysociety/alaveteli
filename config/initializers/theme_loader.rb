# -*- encoding : utf-8 -*-
# This is a global array of route extensions. Alaveteli modules may add to it.
# It is used by our config/routes.rb to decide which route extension files to load.
$alaveteli_route_extensions = []

def theme_root(theme_name)
  Rails.root.join('lib/themes', theme_name)
end

def require_theme(theme_name)
  root = theme_root(theme_name)
  theme_lib = root.join('lib')
  $LOAD_PATH.unshift theme_lib.to_s

  theme_main_include = theme_lib.join('alavetelitheme.rb')

  return unless File.exist?(theme_main_include)

  require theme_main_include

  Rails.configuration.paths.add(
    'config/refusal_advice',
     with: root.join('config/refusal_advice'),
     glob: '*.yml'
  )
end

if Rails.env == "test"
  # By setting this ALAVETELI_TEST_THEME to a theme name, theme tests can run in the Rails
  # context with the theme loaded. Otherwise the themes from the config aren't loaded in testing
  # so they don't interfere with core Alaveteli tests
  if defined? ALAVETELI_TEST_THEME
    require_theme(ALAVETELI_TEST_THEME)
  end
else
  for url in AlaveteliConfiguration::theme_urls.reverse
    require_theme theme_url_to_theme_name(url)
  end
end
