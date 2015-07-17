# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'when making stripping cookies' do

  it 'should not set a cookie when no significant session data is set' do
    get 'country_message'
    response.headers['Set-Cookie'].should be_blank
  end

end
