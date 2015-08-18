# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'globalize3 and strip_attributes' do

  it 'strips spaces from attributes in the default locale' do
    body = FactoryGirl.build(:public_body, :name => ' Trailing Spaces ')
    body.translations_attributes = { :es => { :locale => 'es',
                                              :name => ' El Body ' } }
    body.save!
    body.reload
    expect(body.name).to eq('Trailing Spaces')
  end

  it 'strips spaces from attributes in an alternative locale' do
    body = FactoryGirl.build(:public_body, :name => ' Trailing Spaces ')
    body.translations_attributes = { :es => { :locale => 'es',
                                              :name => ' El Body ' } }
    body.save!
    body.reload
    expect(body.name(:es)).to eq('El Body')
  end

end
