require 'benchmark'

def test(s)
  ret = ""
  if s =~ /^\#<|^$/ or s == "GetText"
  #if s.size == 0 or s[0..1] = "#<" or s == "GetText"
    ret = Object
  end
  ret
end

num = 100000

Benchmark.bm(25){|x|
  x.report("test matched"){ num.times{|i|
    test("#<foo>")
  } }
  x.report("test matched nodata"){ num.times{|i|
    test("")
  } }
  x.report("test matched GetText"){ num.times{|i|
    test("GetText")
  } }
  x.report("test not matched"){ num.times{|i|
    test("FooBar")
  } }

}
