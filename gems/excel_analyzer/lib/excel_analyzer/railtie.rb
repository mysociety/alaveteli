require "rails"
require "active_storage"

module ExcelAnalyzer
  ##
  # This Railtie integrates the gem with Rails by extending ActiveStorage's
  # Analyzers.
  #
  class Railtie < Rails::Railtie
    config.active_storage.analyzers.prepend ExcelAnalyzer::EmlAnalyzer
    config.active_storage.analyzers.prepend ExcelAnalyzer::XlsxAnalyzer
    config.active_storage.analyzers.prepend ExcelAnalyzer::XlsAnalyzer
  end
end
