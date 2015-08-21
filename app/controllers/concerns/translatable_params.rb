module TranslatableParams

  def translatable_params(keys, params)
    WhitelistedParams.new(keys).whitelist(params)
  end

  extend ActiveSupport::Concern

  # Class to whitelist the parameters hash for a model that accepts
  # translation data via "accepts_nested_attributes_for :translations"
  #
  #
  # keys - a hash with keys :general_keys and :translated_keys
  #        containing the list of whitelisted keys for
  #        the base model, and for translations, respectively.
  class WhitelistedParams

    attr_reader :keys

    def initialize(keys)
      @keys = keys
    end

    # Return a whitelisted params hash given the raw params
    # params - the param hash to be whitelisted
    def whitelist(params)
      sliced_params = params.slice(*model_keys)
      slice_translations_params(sliced_params)
    end

    private

    def model_keys
      keys[:translated_keys] + keys[:general_keys] + [:translations_attributes]
    end

    def translation_keys
      keys[:translated_keys] + [:id]
    end

    def slice_translations_params(sliced_params)
      if translation_params = sliced_params[:translations_attributes]
        translation_params.each do |locale, attributes|
          translation_params[locale] = attributes.slice(*translation_keys)
        end
      end
      sliced_params
    end

  end

end
