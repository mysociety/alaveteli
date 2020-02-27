# Module that supplies a helper method to ensure that parameters are converted
# - unalterered - to a Hash whether the input is nil, a Hash (Rails 4), an
# instance of ActionController::Parameters (Rails 5) or an empty Hash (Rails 5)
#
module HashableParams
  extend ActiveSupport::Concern

  def params_to_unsafe_hash(input_params)
    return {} if input_params.blank?
    input_params.to_unsafe_h
  end
end
