# -*- encoding : utf-8 -*-
require 'spec_helper'

describe 'alaveteli_pro/account_request/new.html.erb' do

  before do
    render
  end

  it 'renders an in page link to the account request form' do
    expect(rendered).to have_css('a#launch-access')
  end

  it 'includes the account request form' do
    expect(rendered).to have_css('form #account_request_email')
  end

end
