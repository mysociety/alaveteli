
describe 'Iconv' do
  before do
    @fake_load_path = File.join('spec','fast_gettext','vendor','fake_load_path')
  end

  after do
    $LOAD_PATH.delete @fake_load_path
  end

  it "also works when Iconv was not found locally" do
    #prepare load path
    $LOAD_PATH.unshift @fake_load_path
    test = 1
    begin
      require 'iconv'
    rescue LoadError
      test = 2
    end
    test.should == 2

    #load fast_gettext
    require 'fast_gettext'

    FastGettext.add_text_domain('test',:path=>File.join('spec','locale'))
    FastGettext.text_domain = 'test'
    FastGettext.available_locales = ['en','de']
    FastGettext.locale = 'de'

    #translate
    FastGettext._('car').should == 'Auto'
  end
end