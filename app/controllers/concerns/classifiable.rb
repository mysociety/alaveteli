##
# This module contains shared methods for InfoRequest classification
#
module Classifiable
  extend ActiveSupport::Concern

  included do
    # rubocop:disable Style/ClassVars, Lint/HandleExceptions
    @@custom_states_loaded = false
    begin
      require 'customstates'
      include RequestControllerCustomStates
      @@custom_states_loaded = true
    rescue LoadError, NameError
    end
    # rubocop:enable Style/ClassVars, Lint/HandleExceptions
  end
end
