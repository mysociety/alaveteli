require "rails"
require "active_storage"

module ExcelAnalyzer
  ##
  # This Railtie integrates the gem with Rails by extending ActiveStorage's
  # Analyzers with the custom ExcelAnalyzer::Analyzer.
  #
  class Railtie < Rails::Railtie
    config.active_storage.analyzers.prepend ExcelAnalyzer::Analyzer
  end
end
