# -*- coding: utf-8 -*-
class WorldFOIWebsites
    def self.world_foi_websites
        world_foi_websites = [
                              {:name => "WhatDoTheyKnow",
                                  :country_name => "United Kingdom",
                                  :country_iso_code => "GB",
                                  :url => "http://www.whatdotheyknow.com"},
                              {:name => "Informata Zyrtare",
                                  :country_name => "Kosova",
                                  :country_iso_code => "XK",
                                  :url => "http://informatazyrtare.org"},
                              {:name => "Ask The EU",
                                  :country_name => "European Union",
                                  :country_iso_code => "",
                                  :url => "http://asktheeu.org"},
                              {:name => "MuckRock.com",
                                  :country_name => "United States of America",
                                  :country_iso_code => "US",
                                  :url => "http://www.muckrock.com"},
                              {:name => "FYI",
                                  :country_name => "New Zealand",
                                  :country_iso_code => "NZ",
                                  :url => "http://fyi.org.nz"},
                              {:name => "Frag den Staat",
                                  :country_name => "Deutschland",
                                  :country_iso_code => "DE",
                                  :url => "http://fragdenstaat.de"},
                              {:name => "tu derecho a saber",
                                  :country_name => "España",
                                  :country_iso_code => "ES",
                                  :url => "http://tuderechoasaber.es"},
                              {:name => "Queremos Saber",
                                  :country_name => "Brasil",
                                  :country_iso_code => "BR",
                                  :url => "http://queremossaber.org.br"},
                              {:name => "Ki Mit Tud",
                                  :country_name => "Magyarország",
                                  :country_iso_code => "HU",
                                  :url => "http://kimittud.atlatszo.hu/"},
                              {:name => "PravoDaSznam",
                                  :country_name => "Bosna i Hercegovina",
                                  :country_iso_code => "BA",
                                  :url => "http://www.pravodaznam.ba/"},
                              {:name => "Acceso Intelligente",
                                  :country_name => "Chile",
                                  :country_iso_code => "CL",
                                  :url => "http://accesointeligente.org"}]
        return world_foi_websites
    end

    def self.by_code(code)
        result = self.world_foi_websites.find{|x| x[:country_iso_code].downcase == code.downcase}
        return result
    end
end
            
