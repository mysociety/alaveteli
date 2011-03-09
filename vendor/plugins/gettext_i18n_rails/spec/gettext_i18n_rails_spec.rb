require File.expand_path("spec_helper", File.dirname(__FILE__))

FastGettext.silence_errors

describe GettextI18nRails do
  before do
    GettextI18nRails.translations_are_html_safe = nil
  end

  it "extends all classes with fast_gettext" do
    _('test')
  end

  describe 'translations_are_html_safe' do
    before do
      GettextI18nRails.translations_are_html_safe = nil
    end

    it "makes translations not html_safe by default" do
      _('x').html_safe?.should == false
      s_('x').html_safe?.should == false
      n_('x','y',2).html_safe?.should == false
      String._('x').html_safe?.should == false
      String.s_('x').html_safe?.should == false
      String.n_('x','y',2).html_safe?.should == false
    end

    it "makes instance translations html_safe when wanted" do
      GettextI18nRails.translations_are_html_safe = true
      _('x').html_safe?.should == true
      s_('x').html_safe?.should == true
      n_('x','y',2).html_safe?.should == true
    end

    it "makes class translations html_safe when wanted" do
      GettextI18nRails.translations_are_html_safe = true
      String._('x').html_safe?.should == true
      String.s_('x').html_safe?.should == true
      String.n_('x','y',2).html_safe?.should == true
    end

    it "does not make everything html_safe" do
      'x'.html_safe?.should == false
    end
  end

  it "sets up out backend" do
    I18n.backend.is_a?(GettextI18nRails::Backend).should be_true
  end

  it "has a VERSION" do
    GettextI18nRails::VERSION.should =~ /^\d+\.\d+\.\d+$/
  end

  describe 'FastGettext I18n interaction' do
    before do
      FastGettext.available_locales = nil
      FastGettext.locale = 'de'
    end

    it "links FastGettext with I18n locale" do
      FastGettext.locale = 'xx'
      I18n.locale.should == :xx
    end

    it "does not set an not-accepted locale to I18n.locale" do
      FastGettext.available_locales = ['de']
      FastGettext.locale = 'xx'
      I18n.locale.should == :de
    end

    it "links I18n.locale and FastGettext.locale" do
      I18n.locale = :yy
      FastGettext.locale.should == 'yy'
    end

    it "does not set a non-available locale though I18n.locale" do
      FastGettext.available_locales = ['de']
      I18n.locale = :xx
      FastGettext.locale.should == 'de'
      I18n.locale.should == :de
    end
  end
end