require 'spec/spec_helper'
require 'fast_gettext/translation_repository/base'

describe 'FastGettext::TranslationRepository::Base' do
  before do
    @rep = FastGettext::TranslationRepository::Base.new('x')
  end

  it "can be built" do
    @rep.available_locales.should == []
  end

  it "cannot translate" do
    @rep['car'].should == nil
  end

  it "cannot pluralize" do
    @rep.plural('Axis','Axis').should == ['Axis','Axis']
  end
end