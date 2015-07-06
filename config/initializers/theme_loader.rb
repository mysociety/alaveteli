# -*- encoding : utf-8 -*-
# This is a global array of route extensions. Alaveteli modules may add to it.
# It is used by our config/routes.rb to decide which route extension files to load.
$alaveteli_route_extensions = []

def require_theme(theme_name)
    theme_lib = Rails.root.join 'lib', 'themes', theme_name, 'lib'
    $LOAD_PATH.unshift theme_lib.to_s
    theme_main_include = Rails.root.join theme_lib, "alavetelitheme.rb"
    if File.exists? theme_main_include
        require theme_main_include
    end
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
