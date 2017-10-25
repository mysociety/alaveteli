# -*- encoding : utf-8 -*-
require 'spec_helper'

describe 'alaveteli_pro/account_request/new.html.erb' do

  context 'when pro_pricing is disabled' do

    before do
      render
    end

    it 'renders an in page link to the account request form' do
      expect(rendered).to have_css('a#launch-access')
    end

    it 'includes the account request form' do
      expect(rendered).to have_css('form #account_request_email')
    end

    it 'does not link to the pricing page' do
      expect(rendered).to_not have_link(href: pro_plans_path)
    end

  end

  context 'when pro_pricing is enabled' do

    before do
      with_feature_enabled(:pro_pricing) do
        render
      end
    end

    it 'links to the pricing page' do
      expect(rendered).to have_link(href: pro_plans_path)
    end

    it 'does not include the account request form' do
      expect(rendered).to_not have_css('form #account_request_email')
    end

  end

end
