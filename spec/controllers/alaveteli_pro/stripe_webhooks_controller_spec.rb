# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::StripeWebhooksController do

  describe '#receive' do

    it 'returns a successful response' do
      with_feature_enabled(:alaveteli_pro) do
        post :receive
        expect(response).to be_success
      end
    end

  end

end
