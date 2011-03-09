require 'spec/spec_helper'

describe 'FastGettext::TranslationRepository::Po' do
  before do
    @rep = FastGettext::TranslationRepository.build('test',:path=>File.join('spec','locale'),:type=>:po)
    @rep.is_a?(FastGettext::TranslationRepository::Po).should be_true
  end

  it "can be built" do
    @rep.available_locales.sort.should == ['de','en']
  end

  it "can translate" do
    FastGettext.locale = 'de'
    @rep['car'].should == 'Auto'
  end

  it "can pluralize" do
    FastGettext.locale = 'de'
    @rep.plural('Axis','Axis').should == ['Achse','Achsen']
  end

  it "has access to the mo repositories pluralisation rule" do
    FastGettext.locale = 'en'
    rep = FastGettext::TranslationRepository.build('plural_test',:path=>File.join('spec','locale'),:type=>:po)
    rep['car'].should == 'Test'#just check it is loaded correctly
    rep.pluralisation_rule.call(2).should == 3
  end

  describe 'fuzzy' do
    it "should warn on fuzzy by default" do
      $stderr.should_receive(:print).at_least(:once)
      FastGettext::TranslationRepository.build('test',:path=>File.join('spec','fuzzy_locale'),:type=>:po)
    end

    it "should ignore fuzzy when told to do so" do
      $stderr.should_not_receive(:print)
      FastGettext::TranslationRepository.build('test',:path=>File.join('spec','fuzzy_locale'),:type=>:po, :ignore_fuzzy => true)
    end
  end
  
  describe 'obsolete' do
    it "should warn on obsolete by default" do
      $stderr.should_receive(:print).at_least(:once)
      FastGettext::TranslationRepository.build('test',:path=>File.join('spec','obsolete_locale'),:type=>:po)
    end
  
    it "should ignore obsolete when told to do so" do
      $stderr.should_not_receive(:print)
      FastGettext::TranslationRepository.build('test',:path=>File.join('spec','obsolete_locale'),:type=>:po, :ignore_obsolete => true)
    end
  end
end