$:.unshift "../../locale/lib"
$:.unshift "../../gettext/lib"

#require 'rubygems'
require 'benchmark'
require 'gettext'

num = 100000

def memory
  pid = Process.pid
  map = `pmap -d #{pid}`
  map.split("\n").last.strip.squeeze(' ').split(' ')[3].to_i
end

curr_mem = memory

class Test
  include GetText
  bindtextdomain("test1", :path => "../test/locale")
  def test
    _("language")
  end
end

p GetText::VERSION
Benchmark.bm(25){|x|
  x.report("bindtextdomain"){ num.times{|i|
    GetText.bindtextdomain("test1", :path => "../test/locale")
    #GetText.bindtextdomain("test1", "../test/locale")
  } }
  x.report("set_locale"){ num.times{|i|
    GetText.locale = "ja"
  } }
  GetText.locale = "ja"
  x.report("gettext ja"){ num.times{|i|
    GetText._("language")
  } }
  GetText.locale = "en"
  x.report("gettext en (not found)"){ num.times{|i|
    GetText._("language")
  } }

  GetText.bindtextdomain("plural", :path => "../test/locale")
  #GetText.bindtextdomain("plural", "../test/locale")
  GetText.locale = "ja"
  x.report("ngettext ja"){ (num / 2).times{|i|
    GetText.n_("single", "plural", 1)
    GetText.n_("single", "plural", 2)
  } }
  GetText.locale = "en"
  x.report("ngettext en (not found)"){ (num / 2).times{|i|
    GetText.n_("single", "plural", 1)
    GetText.n_("single", "plural", 2)
  } }

  GetText.locale = "ja"
  x.report("create object ja"){ num.times{|i|
      Test.new.test
  } }
  GetText.locale = "en"
  x.report("create object en"){ num.times{|i|
      Test.new.test
  } }
}

GC.start
puts "#{memory - curr_mem}K "
