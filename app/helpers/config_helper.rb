module ConfigHelper
    def site_name
        Configuration::site_name
    end

    def force_registration_on_new_request
        Configuration::force_registration_on_new_request
    end
end