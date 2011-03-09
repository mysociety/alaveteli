require 'spec/spec_helper'

describe 'unconfigured' do
  it "gives a useful error message when trying to just translate" do
    FastGettext.text_domain = nil
    begin
      FastGettext._('x')
      "".should == "success!?"
    rescue FastGettext::Storage::NoTextDomainConfigured
    end
  end

  it "gives a useful error message when only locale was set" do
    FastGettext.locale = 'de'
    begin
      FastGettext._('x')
      "".should == "success!?"
    rescue FastGettext::Storage::NoTextDomainConfigured
    end
  end
end