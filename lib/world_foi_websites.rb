class WorldFOIWebsites
    def self.world_foi_websites
        world_foi_websites = [
                              {:name => "WhatDoTheyKnow?",
                                  :country_name => _("United Kingdom"),
                                  :country_iso_code => "GB",
                                  :url => "http://www.whatdotheyknow.com"},
                              {:name => "Informata Zyrtare",
                                  :country_name => _("Kosovo"),
                                  :country_iso_code => "XK",
                                  :url => "http://informatazyrtare.org"},
                              {:name => "Ask The EU",
                                  :country_name => _("European Union"),
                                  :country_iso_code => "",
                                  :url => "http://asktheu.org"},
                              {:name => "MuckRock.com",
                                  :country_name => _("United States of America"),
                                  :country_iso_code => "US",
                                  :url => "http://www.muckrock.com"},
                              {:name => "FYI",
                                  :country_name => _("New Zealand"),
                                  :country_iso_code => "NZ",
                                  :url => "http://fyi.org.nz"},
                              {:name => "Frag den Staat",
                                  :country_name => _("Germany"),
                                  :country_iso_code => "DE",
                                  :url => "http://fragdenstaat.de"},
                              {:name => "Acceso Intelligente",
                                  :country_name => _("Chile"),
                                  :country_iso_code => "CL",
                                  :url => "accesointeligente.org"}]
        return world_foi_websites
    end

    def self.by_code(code)
        result = self.world_foi_websites.find{|x| x[:country_iso_code].downcase == code.downcase}
        return result
    end
end
            
