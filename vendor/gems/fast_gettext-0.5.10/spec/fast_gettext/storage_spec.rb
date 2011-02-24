require 'spec/spec_helper'

describe 'Storage' do
  include FastGettext::Storage

  before do
    #reset everything to nil
    self.available_locales = nil
    self.default_text_domain = nil
    self.default_locale = nil
    send(:_locale=,nil)#nil is not allowed to be set...
    default_locale.should be_nil
    available_locales.should be_nil
    locale.should == 'en'
  end

  def thread_save(method, value)
    send("#{method}=",value)

    # mess around with other threads
    100.times do
      Thread.new {FastGettext.send("#{method}=",'en')}
    end
    
    send(method) == value
  end

  {:locale=>'de', :available_locales=>['de'], :text_domain=>'xx', :pluralisation_rule=>lambda{|x|x==4}}.each do |method, value|
    it "stores #{method} thread-save" do
      thread_save(method, value).should == true
    end
  end

  it "stores translation_repositories non-thread-safe" do
    self.translation_repositories[:x]=1
    t = Thread.new{self.translation_repositories[:x]=2}
    t.join
    self.translation_repositories[:x].should == 2
  end

  describe :pluralisation_rule do
    it "defaults to singular-if-1 when it is not set" do
      stub!(:current_repository).and_return mock('',:pluralisation_rule=>nil)
      self.pluralisation_rule = nil
      pluralisation_rule.call(1).should == false
      pluralisation_rule.call(0).should == true
      pluralisation_rule.call(2).should == true
    end
  end

  describe :default_locale do
    it "stores default_locale non-thread-safe" do
      thread_save(:default_locale, 'de').should == false
    end

    it "does not overwrite locale" do
      self.locale = 'de'
      self.default_locale = 'yy'
      self.locale.should == 'de'
    end

    it "falls back to default if locale is missing" do
      self.default_locale = 'yy'
      self.locale.should == 'yy'
    end

    it "does not set non-available-locales as default" do
      self.available_locales = ['xx']
      self.default_locale = 'yy'
      self.default_locale.should == nil
    end

    it "can set default_locale to nil" do
      self.default_locale = 'xx'
      self.default_locale = nil
      default_locale.should be_nil
    end
  end

  describe :default_text_domain do
    it "stores default_text_domain non-thread-safe" do
      thread_save(:default_text_domain, 'xx').should == false
    end

    it "uses default_text_domain when text_domain is not set" do
      self.text_domain = nil
      self.default_text_domain = 'x'
      text_domain.should == 'x'
    end

    it "does not use default when domain is set" do
      self.text_domain = 'x'
      self.default_text_domain = 'y'
      text_domain.should == 'x'
    end
  end

  describe :default_available_locales do
    after do
      self.default_available_locales = nil
    end

    it "stores default_available_locales non-thread-safe" do
      thread_save(:default_available_locales, 'xx').should == false
    end

    it "converts locales to s" do
      self.available_locales = [:x]
      available_locales.should == ['x']
    end

    it "uses default_available_locales when available_locales is not set" do
      self.available_locales = nil
      self.default_available_locales = ['x']
      available_locales.should == ['x']
    end

    it "does not use default when available_locales is set" do
      self.available_locales = ['x']
      self.default_available_locales = ['y']
      available_locales.should == ['x']
    end
  end

  describe :locale do
    it "stores everything as long as available_locales is not set" do
      self.available_locales = nil
      self.locale = 'XXX'
      locale.should == 'XXX'
    end

    it "is en if no locale and no available_locale were set" do
      FastGettext.send(:_locale=,nil)
      self.available_locales = nil
      locale.should == 'en'
    end

    it "does not change the locale if locales was called with nil" do
      self.locale = nil
      locale.should == 'en'
    end

    it "is the first available_locale if one was set" do
      self.available_locales = ['de']
      locale.should == 'de'
    end

    it "does not store a locale if it is not available" do
      self.available_locales = ['de']
      self.locale = 'en'
      locale.should == 'de'
    end

    it "set_locale returns the old locale if the new could not be set" do
      self.locale = 'de'
      self.available_locales = ['de']
      self.set_locale('en').should == 'de'
    end

    {
      'Opera' => "de-DE,de;q=0.9,en;q=0.8",
      'Firefox' => "de-de,de;q=0.8,en-us;q=0.5,en;q=0.3",
    }.each do |browser,accept_language|
      it "sets the locale from #{browser} headers" do
        FastGettext.available_locales = ['de_DE','de','xx']
        FastGettext.locale = 'xx'
        FastGettext.locale = accept_language
        FastGettext.locale.should == 'de_DE'
      end
    end

    it "sets a unimportant locale if it is the only available" do
      FastGettext.available_locales = ['en','xx']
      FastGettext.locale = "de-de,de;q=0.8,en-us;q=0.5,en;q=0.3"
      FastGettext.locale.should == 'en'
    end

    it "sets the locale with the highest wheight" do
      FastGettext.available_locales = ['en','de']
      FastGettext.locale = "xx-us;q=0.5,de-de,de;q=0.8,en;q=0.9"
      FastGettext.locale.should == 'en'
    end

    it "sets the locale from languages" do
      FastGettext.available_locales = ['de']
      FastGettext.locale = "xx-us;q=0.5,de-de;q=0.8,en-uk;q=0.9"
      FastGettext.locale.should == 'de'
    end

    it "sets locale from comma seperated" do
      FastGettext.available_locales = ['de_DE','en','xx']
      FastGettext.locale = "de,de-de,en"
      FastGettext.locale.should == 'de_DE'
    end
  end

  describe :silence_errors do
    before do
      FastGettext.text_domain = 'xxx'
    end

    it "raises when a textdomain was empty" do
      begin 
        FastGettext._('x')
        "".should == "success!?"
      rescue FastGettext::Storage::NoTextDomainConfigured
      end
    end

    it "can silence erros" do
      FastGettext.silence_errors
      FastGettext._('x').should == 'x'
    end
  end

  describe :current_cache do
    before do
      FastGettext.text_domain = 'xxx'
      FastGettext.available_locales = ['de','en']
      FastGettext.locale = 'de'
      FastGettext.current_repository.stub!(:"[]").with('abc').and_return 'old'
      FastGettext.current_repository.stub!(:"[]").with('unfound').and_return nil
      FastGettext._('abc')
      FastGettext._('unfound')
      FastGettext.locale = 'en'
    end

    it "stores a translation seperate by locale" do
      FastGettext.current_cache['abc'].should == nil
    end

    it "stores a translation seperate by domain" do
      FastGettext.locale = 'de'
      FastGettext.text_domain = nil
      FastGettext.current_cache['abc'].should == nil
    end

    it "cache is restored through setting of default_text_domain" do
      FastGettext.locale = 'de'
      FastGettext.text_domain = nil
      FastGettext.default_text_domain = 'xxx'
      FastGettext.current_cache['abc'].should == 'old'
    end

    it "cache is restored through setting of default_locale" do
      FastGettext.send(:_locale=,nil)#reset locale to nil
      FastGettext.default_locale = 'de'
      FastGettext.locale.should == 'de'
      FastGettext.current_cache['abc'].should == 'old'
    end

    it "stores a translation permanently" do
      FastGettext.locale = 'de'
      FastGettext.current_cache['abc'].should == 'old'
    end

    it "stores a unfound translation permanently" do
      FastGettext.locale = 'de'
      FastGettext.current_cache['unfound'].should == false
    end
  end

  describe :key_exist? do
    it "does not find default keys" do
      FastGettext._('abcde')
      key_exist?('abcde').should be_false
    end

    it "finds using the current repository" do
      should_receive(:current_repository).and_return '1234'=>'1'
      key_exist?('1234').should == true
    end

    it "sets the current cache with a found result" do
      should_receive(:current_repository).and_return 'xxx'=>'1'
      key_exist?('xxx')
      current_cache['xxx'].should == '1'
    end

    it "does not overwrite an existing cache value" do
      current_cache['xxx']='xxx'
      stub!(:current_repository).and_return 'xxx'=>'1'
      key_exist?('xxx')
      current_cache['xxx'].should == 'xxx'
    end

    it "is false for gettext meta key" do
      key_exist?("").should == false
    end
  end

  describe :cached_find do
    it "is nil for gettext meta key" do
      cached_find("").should == false
    end
  end

  describe FastGettext::Storage::NoTextDomainConfigured do
    it "shows what to do" do
      FastGettext::Storage::NoTextDomainConfigured.new.to_s.should =~ /FastGettext\.add_text_domain/
    end

    it "warns when text_domain is nil" do
      FastGettext.text_domain = nil
      FastGettext::Storage::NoTextDomainConfigured.new.to_s.should =~ /\(nil\)/
    end

    it "shows current text_domain" do
      FastGettext.text_domain = 'xxx'
      FastGettext::Storage::NoTextDomainConfigured.new('xxx').to_s.should =~ /xxx/
    end
  end
end