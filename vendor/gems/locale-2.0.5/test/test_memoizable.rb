require 'locale/util/memoizable'
require 'test/unit'

class A
  include Locale::Util::Memoizable
  def initialize
    @count = 0
    @a = ""
  end
  def test1(a)
    @a += String(a)
    @count += 1
  end
  memoize :test1
  attr_reader :a
end

class B < A
end

class C < A
  def test1(a)
    @a = String(a) + @a
    @count += 1
  end
  memoize :test1
end

class D
  class << self
    include Locale::Util::Memoizable
    def init
      @@count = 0
      @@a = "a"
    end
    def test1(a)
      @@a = @@a + "b" * a 
      @@count += 1
    end
    memoize :test1
    def a
      @@a
    end
  end
end

class E
  include Locale::Util::Memoizable
  def test2
    "aa"
  end
  memoize :test2

  def test2_dup
    "bb"
  end
  memoize_dup :test2_dup
end

class TestMemoizable < Test::Unit::TestCase
  def test_simple
    t = A.new
    assert_equal 1, t.test1(1)
    assert_equal "1", t.a
    assert_equal 1, t.test1(1)
    assert_equal "1", t.a
    assert_equal 2, t.test1(2)
    assert_equal "12", t.a
    assert_equal 2, t.test1(2)
    assert_equal "12", t.a
    assert_equal 1, t.test1(1)
    assert_equal "12", t.a
  end

  def test_simple_inherited
    t = B.new
    assert_equal 1, t.test1(1)
    assert_equal "1", t.a
    assert_equal 1, t.test1(1)
    assert_equal "1", t.a
    assert_equal 2, t.test1(2)
    assert_equal "12", t.a
    assert_equal 2, t.test1(2)
    assert_equal "12", t.a
    assert_equal 1, t.test1(1)
    assert_equal "12", t.a
  end

  def test_override
    t = C.new
    assert_equal 1, t.test1(1)
    assert_equal "1", t.a
    assert_equal 1, t.test1(1)
    assert_equal "1", t.a
    assert_equal 2, t.test1(2)
    assert_equal "21", t.a
    assert_equal 2, t.test1(2)
    assert_equal "21", t.a
    assert_equal 1, t.test1(1)
    assert_equal "21", t.a
  end

  def test_class_method
     D.init
     assert_equal 1, D.test1(1)
     assert_equal "ab", D.a
     assert_equal 1, D.test1(1)
     assert_equal "ab", D.a
     assert_equal 2, D.test1(2)
     assert_equal "abbb", D.a
     assert_equal 2, D.test1(2)
     assert_equal "abbb", D.a
     assert_equal 1, D.test1(1)
     assert_equal "abbb", D.a
  end

  def test_freeze_or_dup
    t = E.new
    assert_equal "aa", t.test2
    # When modification attempted on frozen objects,
    # ruby 1.9 raises RuntimeError instead of TypeError.
    # http://redmine.ruby-lang.org/issues/show/409
    # http://redmine.ruby-lang.org/repositories/diff/ruby-19/error.c?rev=7294
    if RUBY_VERSION < '1.9.0'
      assert_raise(TypeError){ t.test2 << "a" }
    else
      assert_raise(RuntimeError){ t.test2 << "a" }
    end
    assert_equal "bb", t.test2_dup
    assert_equal "bbb", t.test2_dup << "b"
    assert_equal "bb", t.test2_dup
  end
end
