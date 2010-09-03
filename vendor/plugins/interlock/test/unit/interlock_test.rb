require "#{File.dirname(__FILE__)}/../test_helper"

class InterlockTest < Test::Unit::TestCase
  def test_caching_key_requires_controller_and_action
    assert_raises ArgumentError do
      Interlock.caching_key nil, nil, nil, nil
    end
  end
  
  def test_caching_key_prevents_too_long_keys
    assert_equal Interlock::KEY_LENGTH_LIMIT,
      Interlock.caching_key('controller', 'action', 'id', 'x'*Interlock::KEY_LENGTH_LIMIT).size,
      "keys longer than #{Interlock::KEY_LENGTH_LIMIT} will result in errors from memcache-client"
  end
  
  def test_caching_key_strips_whitespace
    assert_no_match Interlock::ILLEGAL_KEY_CHARACTERS_PATTERN,
      Interlock.caching_key('controller', 'action', 'id', 'tag with illegal characters')
      'generated keys should not contain illegal characters'
  end
  
  def disabled_test_register_dependencies_with_many_keys_one_dependency    
    assert_nothing_raised do
      (1..5000).each do |i|
        Interlock.register_dependencies({Item=>:id}, Interlock.caching_key("a"*200, "show", i, nil))
      end
    end    
  end
  
end