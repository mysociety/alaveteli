require 'spec/spec_helper'

describe 'FastGettext::TranslationRepository::Yaml' do
  before do
    FastGettext.pluralisation_rule = nil
    @rep = FastGettext::TranslationRepository.build('test', :path => File.join('spec', 'locale', 'yaml'), :type => :yaml)
    @rep.is_a?(FastGettext::TranslationRepository::Yaml).should be_true
    FastGettext.locale = 'de'
  end

  it "can be built" do
    @rep.available_locales.sort.should == ['de', 'en']
  end

  it "translates nothing when locale is unsupported" do
    FastGettext.locale = 'xx'
    @rep['simple'].should == nil
  end

  it "does not translated categories" do
    @rep['cars'].should == nil
  end

  it "can translate simple" do
    @rep['simple'].should == 'einfach'
  end

  it "can translate nested" do
    @rep['cars.car'].should == 'Auto'
  end

  it "can pluralize" do
    @rep.plural('cars.axis').should == ['Achse', 'Achsen', nil, nil]
  end

  it "handles unfound plurals with nil" do
    @rep.plural('cars.xxx').should == [nil, nil, nil, nil]
  end

  it "can be used to translate plural forms" do
    FastGettext.stub!(:current_repository).and_return @rep
    FastGettext.n_('cars.axis','cars.axis',2).should == 'Achsen'
    FastGettext.n_('cars.axis',2).should == 'Achsen'
    FastGettext.n_('cars.axis',1).should == 'Achse'
  end

  4.times do |i|
    it "can be used to do wanky pluralisation rules #{i}" do
      FastGettext.stub!(:current_repository).and_return @rep
      @rep.stub!(:pluralisation_rule).and_return lambda{i}
      FastGettext.n_('cars.silly',1).should == i.to_s # cars.silly translations are 0,1,2,3
    end
  end

  it "can use custom pluraliztion rules" do
    FastGettext.locale = 'en'
    {0 => 0, 1 => 1, 2 => 2, 3 => 0}.each do |input, expected|
      @rep.pluralisation_rule.call(input).should == expected
    end
  end
end