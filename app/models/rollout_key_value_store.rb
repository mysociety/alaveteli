class RolloutKeyValueStore < ActiveRecord::Base
  # This class is an adapter for the Rollout library to store its feature
  # flags in our database rather than in Redis like it would do by default.
  # They have a simple key:value interface (like Redis) and this class
  # provides methods to mimic Redis' get/set functionality.

  # Set a key (the key will be created if it exist first)
  def set(key,value)
    record = RolloutKeyValueStore.find_or_create_by(key: key)
    record.update_attribute(:value,value)
    record.save
  end

  # Get a key (returns nil if the key doesn't exist)
  def get(key)
    record = RolloutKeyValueStore.find_by(key: key)
    record.nil? ? nil : record.value
  end

  # Delete a key
  def del(key)
    record = RolloutKeyValueStore.find_by(key: key)
    record.destroy if record
  end
end
