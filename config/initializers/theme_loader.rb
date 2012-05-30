theme_urls = MySociety::Config.get("THEME_URLS", [])
if ENV["RAILS_ENV"] != "test" # Don't let the theme interfere with Alaveteli specs
    for url in theme_urls.reverse
        theme_name = url.sub(/.*\/(.*).git/, "\\1")
        theme_main_include = File.expand_path "../../../vendor/plugins/#{theme_name}/lib/alavetelitheme.rb", __FILE__
        if File.exists? theme_main_include
            require theme_main_include
        end
    end
end
