require 'spec/spec_helper'

module FastGettext
  module TranslationRepository
    class Dummy
      attr_accessor :name, :options
      def initialize(name, options)
        @name = name
        @options = options
      end
    end
  end
end

describe FastGettext::TranslationRepository do
  describe "build" do
    it "auto requires class by default" do
      lambda { FastGettext::TranslationRepository.build('xx', { :type => 'invalid'}) }.should raise_error(LoadError)
    end

    it "can have auto-require disabled" do
      FastGettext::TranslationRepository.build('xx', { :type => 'dummy' })
    end

    it "makes a new repository" do
      options = { :type => 'dummy', :external => true }
      repo = FastGettext::TranslationRepository.build('xx', options)
      repo.class.should == FastGettext::TranslationRepository::Dummy
      repo.name.should == 'xx'
      repo.options.should == options
    end
  end
end