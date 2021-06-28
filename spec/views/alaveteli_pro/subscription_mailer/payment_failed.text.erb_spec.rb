require 'spec_helper'

describe 'alaveteli_pro/subscription_mailer/payment_failed.text.erb' do
  subject { render }

  before do
    assign(:user_name, 'Paul Pro')
    assign(:pro_site_name, 'Alaveteli Professional')
    assign(:subscriptions_url, 'http://test.host/en/profile/subscriptions')
    render
  end

  it { is_expected.to eq(read_described_template_fixture) }
end
