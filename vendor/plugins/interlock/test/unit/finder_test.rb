
require "#{File.dirname(__FILE__)}/../test_helper"
require 'fileutils'

class FinderTest < Test::Unit::TestCase

  LOG = "#{HERE}/integration/app/log/development.log"     
  
  ### Finder caching tests
  
  def test_find_without_cache
    # Non-empty options hash bypasses the cache entirely, including the logging
    Item.find(1, {:conditions => "1 = 1"})
    assert_no_match(/model.*Item:find:1:default is loading from the db/, log)
  end
  
  def test_find
    assert_equal Item.find(1, {}),
      Item.find(1)
    assert_match(/model.*Item:find:1:default is loading from the db/, log)

    assert_equal Item.find(1, {}),
      Item.find(1)
    assert_match(/model.*Item:find:1:default is loading from memcached/, log)
  end
  
  def test_find_with_array
    assert_equal Item.find([1, 2], {}),
      Item.find([1, 2])
    assert_match(/model.*Item:find:1:default is loading from the db/, log)
    assert_match(/model.*Item:find:2:default is loading from the db/, log)

    assert_equal Item.find([1, 2], {}),
      Item.find([1, 2])
    assert_match(/model.*Item:find:1:default is loading from memcached/, log)
    assert_match(/model.*Item:find:2:default is loading from memcached/, log)    
  end
  
  def test_single_element_array_returns_array
    assert_equal Item.find([1], {}),
      Item.find([1])
  end
  
  def test_find_raise
    assert_raises(ActiveRecord::RecordNotFound) do
      Item.find(44)
    end
  end

  def test_find_with_array_raise
    assert_raises(ActiveRecord::RecordNotFound) do
      # Once from the DB
      Item.find([1, 2, 44])
    end
    assert_raises(ActiveRecord::RecordNotFound) do
      # Once from Memcached
      Item.find([1, 2, 44])
    end
  end

  def test_find_with_array_ignores_nil
    assert_equal Item.find(1, nil, {}), Item.find(1, nil)
    assert_equal Item.find([1, nil], {}), Item.find([1, nil])
  end

  def test_invalidate
    Item.find(1).save!
    truncate
    Item.find(1)
    assert_match(/model.*Item:find:1:default is loading from the db/, log)
    Item.find(1)
    assert_match(/model.*Item:find:1:default is loading from memcached/, log)  
  end
  
  def test_reload_should_invalidate
    item = Item.find(1)
    item.reload
    assert_match(/model.*Item:find:1:default invalidated with finders/, log)
    truncate
    Item.find(1)
    assert_match(/model.*Item:find:1:default is loading from memcached/, log)  
  end
  
  def test_update_attributes_should_invalidate
    item = Item.find(1)
    name = item.name

    item.update_attributes!(:name => 'Updated')
    updated_item = Item.find(1)
    assert_equal 'Updated', item.name

    # Restore name for further tests
    item.update_attributes!(:name => name)
  end
  
  def test_update_all_should_invalidate
    # TODO
  end
  
  def test_update_counters_should_invalidate
    item = Item.find(1)
    Item.update_counters(1, :counting_something => 1)
    updated_item = Item.find(1)
    assert_equal updated_item.counting_something, item.counting_something + 1
  end

  def test_find_all_by_id
    assert_equal Item.find_all_by_id(44, {}), 
      Item.find_all_by_id(44)
    assert_equal Item.find_all_by_id([1,2], {}), 
      Item.find_all_by_id([1,2])
    assert_equal Item.find_all_by_id(1, 2, {}), 
      Item.find_all_by_id(1, 2)
  end
  
  def test_invalidate_sti
    # XXX Need a regression test
  end

  def test_find_by_id
    assert_equal Item.find_by_id(44, {}), 
      Item.find_by_id(44)
    assert_equal Item.find_by_id([1,2], {}), 
      Item.find_by_id([1,2])
    assert_equal Item.find_by_id(1, 2, {}), 
      Item.find_by_id(1, 2)
  end
  
  def test_custom_log_level
    old_level = RAILS_DEFAULT_LOGGER.level
    RAILS_DEFAULT_LOGGER.level = Logger::INFO

    Interlock.config[:log_level] = 'info'
    truncate
    Item.find(1)
    assert_match(/model.*Item:find:1:default is loading/, log)

    Interlock.config[:log_level] = 'debug'
    truncate
    Item.find(1)
    assert_no_match(/model.*Item:find:1:default is loading/, log)
  ensure
    RAILS_DEFAULT_LOGGER.level = old_level
  end
  
  def test_find_with_nonstandard_primary_key
    db = Book.find_via_db(1137)
    cache = Book.find(1137)
    assert_equal db, cache
    assert_equal Book.find_via_db(1137, 2001, :order => "guid ASC"), Book.find(1137, 2001)
  end
  
  ### Support methods
  
  def setup
    # Change the asset ID; has a similar effect to flushing memcached
    @old_asset_id = ENV['RAILS_ASSET_ID']
    ENV['RAILS_ASSET_ID'] = rand.to_s
    truncate    
  end
  
  def teardown
    # Restore the asset id
    ENV['RAILS_ASSET_ID'] = @old_asset_id
  end

  def truncate
    system("> #{LOG}")
  end
  
  def log
    File.open(LOG, 'r') do |f|
      f.read
    end
  end  
end