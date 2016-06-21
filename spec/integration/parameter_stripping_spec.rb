# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When handling bad requests" do

  it 'should return a 404 for GET requests to a malformed request URL' do
    get 'request/228%85'
    expect(response.status).to eq(404)
  end

end
