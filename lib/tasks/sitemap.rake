namespace :sitemap do
  desc 'Generate the XML sitemap files which tell search engines what to index'
  task generate: :environment do
    if Sitemap.enabled?
      Sitemap.generate!
    else
      puts 'ENABLE_SITEMAP is false. Not generating a sitemap.'
    end
  end
end
