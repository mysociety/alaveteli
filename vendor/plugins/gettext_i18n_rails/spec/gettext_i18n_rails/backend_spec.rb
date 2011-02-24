require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe GettextI18nRails::Backend do
  it "redirects calls to another I18n backend" do
    subject.backend.should_receive(:xxx).with(1,2)
    subject.xxx(1,2)
  end

  describe :available_locales do
    it "maps them to FastGettext" do
      FastGettext.should_receive(:available_locales).and_return [:xxx]
      subject.available_locales.should == [:xxx]
    end

    it "and returns an empty array when FastGettext.available_locales is nil" do
      FastGettext.should_receive(:available_locales).and_return nil
      subject.available_locales.should == []
    end
  end

  describe :translate do
    it "uses gettext when the key is translatable" do
      FastGettext.stub(:current_repository).and_return 'xy.z.u'=>'a'
      subject.translate('xx','u',:scope=>['xy','z']).should == 'a'
    end

    it "interpolates options" do
      FastGettext.stub(:current_repository).and_return 'ab.c'=>'a%{a}b'
      subject.translate('xx','c',:scope=>['ab'], :a => 'X').should == 'aXb'
    end

    it "can translate with gettext using symbols" do
      FastGettext.stub(:current_repository).and_return 'xy.z.v'=>'a'
      subject.translate('xx',:v ,:scope=>['xy','z']).should == 'a'
    end

    it "can translate with gettext using a flat scope" do
      FastGettext.stub(:current_repository).and_return 'xy.z.x'=>'a'
      subject.translate('xx',:x ,:scope=>'xy.z').should == 'a'
    end

    it "uses the super when the key is not translatable" do
      lambda{subject.translate('xx','y',:scope=>['xy','z'])}.should raise_error(I18n::MissingTranslationData)
    end
  end
end