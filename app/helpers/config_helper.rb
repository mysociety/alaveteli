module ConfigHelper
    def site_name
        MySociety::Config.get('SITE_NAME', 'Alaveteli')
    end

    def force_registration_on_new_request
        MySociety::Config.get('FORCE_REGISTRATION_ON_NEW_REQUEST', false)
    end
end