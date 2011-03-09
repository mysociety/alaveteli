require 'spec/spec_helper'

describe FastGettext::Translation do
  include FastGettext::Translation

  before do
    default_setup
  end

  describe "unknown locale" do
    before do
      FastGettext.available_locales = nil
      FastGettext.locale = 'xx'
    end

    it "does not translate" do
      _('car').should == 'car'
    end

    it "does not translate plurals" do
      n_('car','cars',2).should == 'cars'
    end
  end

  describe :_ do
    it "translates simple text" do
      _('car').should == 'Auto'
    end

    it "returns key if not translation was found" do
      _('NOT|FOUND').should == 'NOT|FOUND'
    end

    it "does not return the gettext meta information" do
      _('').should == ''
    end
  end

  describe :n_ do
    before do
      FastGettext.pluralisation_rule = nil
    end

    it "translates pluralized" do
      n_('Axis','Axis',1).should == 'Achse'
      n_('Axis','Axis',2).should == 'Achsen'
      n_('Axis','Axis',0).should == 'Achsen'
    end

    describe "pluralisations rules" do
      it "supports abstract pluralisation rules" do
        FastGettext.pluralisation_rule = lambda{|n|2}
        n_('a','b','c','d',4).should == 'c'
      end

      it "supports false as singular" do
        FastGettext.pluralisation_rule = lambda{|n|n!=2}
        n_('singular','plural','c','d',2).should == 'singular'
      end

      it "supports true as plural" do
        FastGettext.pluralisation_rule = lambda{|n|n==2}
        n_('singular','plural','c','d',2).should == 'plural'
      end
    end
    
    it "returns the appropriate key if no translation was found" do
      n_('NOTFOUND','NOTFOUNDs',1).should == 'NOTFOUND'
      n_('NOTFOUND','NOTFOUNDs',2).should == 'NOTFOUNDs'
    end

    it "returns the last key when no translation was found and keys where to short" do
      FastGettext.pluralisation_rule = lambda{|x|4}
      n_('Apple','Apples',2).should == 'Apples'
    end
  end

  describe :s_ do
    it "translates simple text" do
      s_('car').should == 'Auto'
    end

    it "returns cleaned key if a translation was not found" do
      s_("XXX|not found").should == "not found"
    end

    it "can use a custom seperator" do
      s_("XXX/not found",'/').should == "not found"
    end
  end

  describe :N_ do
    it "returns the key" do
      N_('XXXXX').should == 'XXXXX'
    end
  end

  describe :Nn_ do
    it "returns the keys as array" do
      Nn_('X','Y').should == ['X','Y']
    end
  end

  describe :ns_ do
    it "translates whith namespace" do
      ns_('Fruit|Apple','Fruit|Apples',2).should == 'Apples'
    end
  end


  describe :caching do
    describe :cache_hit do
      before do
        FastGettext.translation_repositories.replace({})
        #singular cache keys
        FastGettext.current_cache['xxx'] = '1'

        #plural cache keys
        FastGettext.current_cache['||||xxx'] = ['1','2']
        FastGettext.current_cache['||||xxx||||yyy'] = ['1','2']
      end

      it "uses the cache when translating with _" do
        _('xxx').should == '1'
      end

      it "uses the cache when translating with s_" do
        s_('xxx').should == '1'
      end

      it "uses the cache when translating with n_" do
        n_('xxx','yyy',1).should == '1'
      end

      it "uses the cache when translating with n_ and single argument" do
        n_('xxx',1).should == '1'
      end
    end

    it "caches different locales seperatly" do
      FastGettext.locale = 'en'
      _('car').should == 'car'
      FastGettext.locale = 'de'
      _('car').should == 'Auto'
    end

    it "caches different textdomains seperatly" do
      _('car').should == 'Auto'

      FastGettext.translation_repositories['fake'] = {}
      FastGettext.text_domain = 'fake'
      _('car').should == 'car'

      FastGettext.text_domain = 'test'
      _('car').should == 'Auto'
    end
  end
end