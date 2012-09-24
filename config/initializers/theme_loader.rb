# This is a global array of route extensions. Alaveteli modules may add to it.
# It is used by our config/routes.rb to decide which route extension files to load.
$alaveteli_route_extensions = []

if ENV["RAILS_ENV"] != "test" # Don't let the themes interfere with Alaveteli specs
    for url in Configuration::theme_urls.reverse
        theme_name = url.sub(/.*\/(.*).git/, "\\1")
        theme_main_include = File.expand_path "../../../vendor/plugins/#{theme_name}/lib/alavetelitheme.rb", __FILE__
        if File.exists? theme_main_include
            require theme_main_include
        end
    end
end
