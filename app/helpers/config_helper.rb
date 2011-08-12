module ConfigHelper
    def site_name
        MySociety::Config.get('SITE_NAME', 'Alaveteli')
    end
end