require "#{File.dirname(__FILE__)}/../test_helper"

class FinderTest < Test::Unit::TestCase
  def test_reload_should_work
    item = Item.find(1)
    assert_equal Item.find(1, {}), item.reload
  end
end