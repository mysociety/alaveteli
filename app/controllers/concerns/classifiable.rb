##
# This module contains shared methods for InfoRequest classification
#
module Classifiable
  extend ActiveSupport::Concern

  included do
    before_action :find_info_request, :authorise_info_request

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

  private

  def find_info_request
    raise NotImplementedError
  end

  def authorise_info_request
    raise NotImplementedError
  end

  def redirect_to_info_request
    raise NotImplementedError
  end
end
