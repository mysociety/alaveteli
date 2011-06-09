require 'cgi'
require 'locale'
require 'test/unit'

class CGI
  module QueryExtension
    # Override this method to avoid to put warning messages.
    module_function
    def readlines=(str)
      @@lines = [str]
    end
    def readlines
      @@lines
    end
    def read_from_cmdline
      require "shellwords"
      string = readlines.join(' ').gsub(/\n/n, '').gsub(/\\=/n, '%3D').gsub(/\\&/n, '%26')
      
      words = Shellwords.shellwords(string)
      
      if words.find{|x| /=/n.match(x) }
        words.join('&')
      else
        words.join('+')
      end
    end
    private :read_from_cmdline
  end
end

class TestDetectCGI < Test::Unit::TestCase
  def setup_cgi(str)
    CGI::QueryExtension.readlines = str
    Locale.init(:driver => :cgi)
    cgi = CGI.new
    Locale.cgi = cgi
    Locale.clear_all
  end

  def test_query_string
    #query string
    setup_cgi("lang=ja_JP")
    lang = Locale.current[0]
    assert_equal(Locale::Tag::Simple, lang.class)
    assert_equal("ja_JP", lang.to_s)

    setup_cgi("lang=ja-jp")
    lang = Locale.current[0]
    assert_equal(Locale::Tag::Simple, lang.class)
    assert_equal("ja_JP", lang.to_s)
    assert_equal("ja-JP", lang.to_rfc.to_s)
    setup_cgi("lang=ja-jp")
    assert_equal("ja_JP", lang.to_s)
    assert_equal("ja-JP", lang.to_rfc.to_s)

  end

  def test_cookie
    #cockie
    setup_cgi("Set-Cookie: lang=en-us")
    assert_equal("en_US", Locale.current.to_s)
  end

  def test_accept_language
    ENV["HTTP_ACCEPT_LANGUAGE"] = ""
    ENV["HTTP_ACCEPT_CHARSET"] = ""
    setup_cgi("")
    lang = Locale.current[0]
    assert_equal(Locale::Tag::Simple, lang.class)
    assert_equal("en", lang.to_s)
    assert_equal("en", lang.to_rfc.to_s)

    ENV["HTTP_ACCEPT_LANGUAGE"] = "ja,en-us;q=0.7,en;q=0.3"
    setup_cgi("")
    lang1, lang2, lang3 = Locale.current
    assert_equal("ja", lang1.to_rfc.to_s)
    assert_equal("en-US", lang2.to_rfc.to_s)
    assert_equal("en", lang3.to_rfc.to_s)

    ENV["HTTP_ACCEPT_LANGUAGE"] = "en-us,ja;q=0.7,en;q=0.3"
    setup_cgi("")
    lang1, lang2, lang3 = Locale.current
    assert_equal("en-US", lang1.to_rfc.to_s)
    assert_equal("ja", lang2.to_rfc.to_s)
    assert_equal("en", lang3.to_rfc.to_s)

    ENV["HTTP_ACCEPT_LANGUAGE"] = "en"
    setup_cgi("")
    lang = Locale.current[0]
    assert_equal("en", lang.to_rfc.to_s)
  end

  def test_accept_charset
    #accept charset
    ENV["HTTP_ACCEPT_CHARSET"] = "Shift_JIS"
    setup_cgi("")
    assert_equal("Shift_JIS", Locale.charset)

    ENV["HTTP_ACCEPT_CHARSET"] = "EUC-JP,*,utf-8"
    setup_cgi("")
    assert_equal("EUC-JP", Locale.charset)

    ENV["HTTP_ACCEPT_CHARSET"] = "*"
    setup_cgi("")
    assert_equal("UTF-8", Locale.charset)

    ENV["HTTP_ACCEPT_CHARSET"] = ""
    setup_cgi("")
    assert_equal("UTF-8", Locale.charset)
  end

  def test_default
    Locale.set_default(nil)
    Locale.set_default("ja-JP")
    ENV["HTTP_ACCEPT_LANGUAGE"] = ""
    ENV["HTTP_ACCEPT_CHARSET"] = ""
    setup_cgi("")
    assert_equal("ja-JP", Locale.default.to_rfc.to_s)
    assert_equal("ja-JP", Locale.current.to_rfc.to_s)
    Locale.set_default(nil)
  end

  def common(*ary)
    ary.map{|v| Locale::Tag::Common.parse(v)}
  end

  def rfc(*ary)
    ary.map{|v| Locale::Tag::Rfc.parse(v)}
  end

  def cldr(*ary)
    ary.map{|v| Locale::Tag::Cldr.parse(v)}
  end

  def simple(*ary)
    ary.map{|v| Locale::Tag::Simple.parse(v)}
  end

  def test_candidates

    ENV["HTTP_ACCEPT_LANGUAGE"] = "fr-fr,zh_CN;q=0.7,zh_TW;q=0.2,ja_JP;q=0.1"
    setup_cgi("")

    assert_equal common("fr-FR", "zh-CN", "zh-TW", "ja-JP", 
                        "fr", "zh", "ja", "en"), Locale.candidates
    
    assert_equal rfc("fr-FR", "zh-CN", "zh-TW", "ja-JP", "fr", 
                     "zh", "ja", "en"), Locale.candidates(:type => :rfc)

    assert_equal cldr("fr_FR", "zh_CN", "zh_TW", "ja_JP", "fr", 
                      "zh", "ja", "en"), Locale.candidates(:type => :cldr)

    assert_equal simple("fr-FR", "zh-CN", "zh-TW", "ja-JP",  
                        "fr", "zh", "ja", "en"), Locale.candidates(:type => :simple)

    taglist = Locale.candidates(:type => :rfc)
    assert_equal Locale::TagList, taglist.class
    assert_equal "fr", taglist.language
    assert_equal "FR", taglist.region

  end

  def test_candidates_with_supported_language_tags
    ENV["HTTP_ACCEPT_LANGUAGE"] = "fr-fr,zh_CN;q=0.7,zh_TW;q=0.2,ja_JP;q=0.1"
    setup_cgi("")

    assert_equal common("fr_FR", "zh", "ja"), Locale.candidates(:type => :common, 
                                                                :supported_language_tags => ["fr_FR", "ja", "zh"])

    assert_equal simple("fr-FR", "zh", "ja"), Locale.candidates(:type => :simple, 
                                                                :supported_language_tags => ["fr-FR", "ja", "zh"])
    #supported_language_tags includes "pt" as not in HTTP_ACCEPT_LANGUAGE
    assert_equal simple("fr-FR", "zh", "ja"), 
    Locale.candidates(:type => :simple, 
                      :supported_language_tags => ["fr-FR", "ja", "zh", "pt"])

  end

  def test_candidates_with_default
    ENV["HTTP_ACCEPT_LANGUAGE"] = "fr-fr,zh_CN;q=0.7,zh_TW;q=0.2,ja_JP;q=0.1"
    setup_cgi("")

    Locale.default = "zh_TW"
    assert_equal simple("fr-FR", "zh", "ja"), 
    Locale.candidates(:type => :simple, 
                      :supported_language_tags => ["fr-FR", "ja", "zh", "pt"])

    Locale.default = "pt"
    assert_equal simple("fr-FR", "zh", "ja", "pt"), 
    Locale.candidates(:type => :simple, 
                      :supported_language_tags => ["fr-FR", "ja", "zh", "pt"])

    # default value is selected even if default is not in supported_language_tags.
    assert_equal simple("pt"), Locale.candidates(:type => :simple, 
                                                 :supported_language_tags => ["aa"])
    Locale.default = "en"
  end


  def test_candidates_with_app_language_tags
    Locale.set_app_language_tags("fr-FR", "ja")

    ENV["HTTP_ACCEPT_LANGUAGE"] = "fr-fr,zh_CN;q=0.7,zh_TW;q=0.2,ja_JP;q=0.1"
    setup_cgi("")

    assert_equal common("fr-FR", "ja"), Locale.candidates

    # default value is selected if default is not in app_language_tags.
    Locale.set_app_language_tags("no", "pt")
    Locale.default = "zh"
    assert_equal common("zh"), Locale.candidates

    Locale.default = "en"
    Locale.set_app_language_tags(nil)
  end
end
