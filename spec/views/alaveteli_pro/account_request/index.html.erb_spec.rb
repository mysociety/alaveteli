require 'spec_helper'

describe 'alaveteli_pro/account_request/index.html.erb' do

  before { render }

  context 'when pro_pricing and pro_self_serve are disabled' do

    it 'renders an in page link to the account request form' do
      expect(rendered).to have_css('a#js-request-access')
    end

    it 'includes the account request form' do
      expect(rendered).to have_css('form #account_request_email')
    end

    it 'does not link to the pricing page' do
      expect(rendered).to_not have_link(href: pro_plans_path)
    end

  end

  context 'when pro_self_serve is enabled', feature: :pro_self_serve do

    it 'renders an submit input for the account self serve form' do
      expect(rendered).to have_css('form input[type=submit]#account_self_serve')
    end

    it 'does not include the account request form' do
      expect(rendered).to_not have_css('form #account_request_email')
    end

  end

  context 'when pro_pricing is enabled', feature: :pro_pricing do

    it 'links to the pricing page' do
      expect(rendered).to have_link(href: pro_plans_path)
    end

    it 'does not include the account request form' do
      expect(rendered).to_not have_css('form #account_request_email')
    end

  end

end
