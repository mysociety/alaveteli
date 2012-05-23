theme_urls = MySociety::Config.get("THEME_URLS", [])
if ENV["RAILS_ENV"] != "test" # Don't let the theme interfere with Alaveteli specs
    for url in theme_urls.reverse
        theme_name = url.sub(/.*\/(.*).git/, "\\1")
        require File.expand_path "../../../vendor/plugins/#{theme_name}/lib/alavetelitheme.rb", __FILE__
    end
end
