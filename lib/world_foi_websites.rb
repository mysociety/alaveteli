# -*- encoding : utf-8 -*-
class WorldFOIWebsites
    EU_COUNTRIES = { 'BE' => 'Belgium',
                     'BG' => 'Bulgaria',
                     'CZ' => 'Czech Republic',
                     'DK' => 'Denmark',
                     'DE' => 'Germany',
                     'EE' => 'Estonia',
                     'IE' => 'Ireland',
                     'GR' => 'Greece',
                     'ES' => 'Spain',
                     'FR' => 'France',
                     'HR' => 'Croatia',
                     'IT' => 'Italy',
                     'CY' => 'Cyprus',
                     'LV' => 'Latvia',
                     'LT' => 'Lithuania',
                     'LU' => 'Luxembourg',
                     'HU' => 'Hungary',
                     'MT' => 'Malta',
                     'NL' => 'Netherlands',
                     'AT' => 'Austria',
                     'PL' => 'Poland',
                     'PT' => 'Portugal',
                     'RO' => 'Romania',
                     'SI' => 'Slovenia',
                     'SK' => 'Slovakia',
                     'FI' => 'Finland',
                     'SE' => 'Sweden',
                     'GB' => 'United Kingdom' }.freeze

  def self.world_foi_websites
    world_foi_websites = [
      { :name => "WhatDoTheyKnow",
        :country_name => "United Kingdom",
        :country_iso_code => "GB",
        :url => "https://www.whatdotheyknow.com" },
      { :name => "Informata Zyrtare",
        :country_name => "Kosova",
        :country_iso_code => "XK",
        :url => "http://informatazyrtare.org" },
      { :name => "Ask The EU",
        :country_name => "European Union",
        :country_iso_code => "",
        :url => "http://asktheeu.org" },
      { :name => "MuckRock.com",
        :country_name => "United States of America",
        :country_iso_code => "US",
        :url => "http://www.muckrock.com" },
      { :name => "FYI",
        :country_name => "New Zealand",
        :country_iso_code => "NZ",
        :url => "http://fyi.org.nz" },
      { :name => "Frag den Staat",
        :country_name => "Deutschland",
        :country_iso_code => "DE",
        :url => "http://fragdenstaat.de" },
      { :name => "tu derecho a saber",
        :country_name => "España",
        :country_iso_code => "ES",
        :url => "http://tuderechoasaber.es" },
      { :name => "Queremos Saber",
        :country_name => "Brasil",
        :country_iso_code => "BR",
        :url => "http://queremossaber.org.br" },
      { :name => "Ki Mit Tud",
        :country_name => "Magyarország",
        :country_iso_code => "HU",
        :url => "http://kimittud.atlatszo.hu/" },
      { :name => "PravoDaSznam",
        :country_name => "Bosna i Hercegovina",
        :country_iso_code => "BA",
        :url => "http://www.pravodaznam.ba/" },
      { :name => "Acceso Intelligente",
        :country_name => "Chile",
        :country_iso_code => "CL",
        :url => "http://accesointeligente.org" },
      { :name => "Right To Know",
        :country_name => "Australia",
        :country_iso_code => "AU",
        :url => "http://www.righttoknow.org.au" },
      { :name => "Informace pro Vsechny",
        :country_name => "Česká republika",
        :country_iso_code => "CZ",
        :url => "http://www.infoprovsechny.cz" },
      { :name => "¿Qué Sabés?",
        :country_name => "Uruguay",
        :country_iso_code => "UY",
        :url => "http://www.quesabes.org/" },
      { :name => "Nu Vă Supărați",
        :country_name => "România",
        :country_iso_code => "RO",
        :url => "http://nuvasuparati.info/" },
      { :name => "Marsoum41",
        :country_name => "تونس",
        :country_iso_code => "TN",
        :url => "http://www.marsoum41.org" },
      { :name => "Доступ до правди",
        :country_name => "Україна",
        :country_iso_code => "UA",
        :url => "https://dostup.pravda.com.ua/" },
      { :name => "Ask Data",
        :country_name => "מְדִינַת יִשְׂרָאֵל",
        :country_iso_code => "IL",
        :url => "http://askdata.org.il/" },
      { :name => "Слободен пристап",
        :country_name => "Република Македонија",
        :country_iso_code => "MK",
        :url => "http://www.slobodenpristap.mk/" },
      { :name => "Imamo pravo znati",
        :country_name => "Republika Hrvatska",
        :country_iso_code => "HR",
        :url => "http://imamopravoznati.org/" },
      { :name => "РосОтвет",
        :country_name => "Россия",
        :country_iso_code => "RU",
        :url => "http://rosotvet.ru/" }
    ]
    return world_foi_websites
  end

  def self.by_code(code)
    result = self.world_foi_websites.find{|x| x[:country_iso_code].downcase == code.downcase}
    return result
  end

  def self.can_ask_the_eu?(code)
    country_in_eu?(code) && !is_ask_the_eu?
  end

  def self.country_in_eu?(code)
    EU_COUNTRIES.key?(code.to_s.upcase)
  end

  def self.is_ask_the_eu?
    AlaveteliConfiguration.domain == 'www.asktheeu.org'
  end

end
