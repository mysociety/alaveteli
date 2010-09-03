
require "#{File.dirname(__FILE__)}/../test_helper"

class LockTest < Test::Unit::TestCase
  
  KEY = "memcached_test"
  LOCK = "lock:#{KEY}"
  
  def setup
    CACHE.delete KEY
    CACHE.delete LOCK  
  end
  
  def test_unlocked
    assert_nil CACHE.get(KEY)
    assert_nil CACHE.get(LOCK)
    
    assert_nothing_raised do
      CACHE.lock(KEY) { "A" }
    end

    assert_nil CACHE.get(LOCK)
    assert_equal("A", CACHE.get(KEY))
  end
  
  def test_locked
    CACHE.set LOCK, "Bogus"

    assert_raises Interlock::LockAcquisitionError do
      CACHE.lock(KEY, 30, 2) { "A" }
    end
    
    assert_equal("Bogus", CACHE.get(LOCK))    
    assert_nil CACHE.get(KEY)
end
  
  def test_ensure_lock_release
    assert_raises RuntimeError do
      CACHE.lock(KEY) { raise }
    end
    
    assert_nil CACHE.get(LOCK)    
  end
    
end
