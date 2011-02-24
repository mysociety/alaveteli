require 'spec/spec_helper'

describe 'FastGettext::TranslationRepository::Logger' do
  before do
    @callback = lambda{}
    @rep = FastGettext::TranslationRepository.build('test', :type=>:logger, :callback=>@callback)
    @rep.is_a?(FastGettext::TranslationRepository::Logger).should be_true
  end
  subject{@rep}

  it{ should have(0).available_locales}

  it "has no pluralisation_rule" do
    @rep.pluralisation_rule.should == nil
  end

  describe :single do
    it "logs every call" do
      @callback.should_receive(:call).with('the_key')
      @rep['the_key']
    end

    it "returns nil" do
      @callback.should_receive(:call).with('the_key').and_return 'something'
      @rep['the_key'].should == nil
    end
  end

  describe :plural do
    it "logs every call" do
      @callback.should_receive(:call).with(['a','b'])
      @rep.plural('a','b')
    end

    it "returns an empty array" do
      @callback.should_receive(:call).with(['a','b']).and_return 'something'
      @rep.plural('a','b').should == []
    end
  end
end