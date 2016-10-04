require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe RolloutKeyValueStore, type: :model do
  before do
    @rollout_store = RolloutKeyValueStore.new
  end

  it "allows setting by key" do
    @rollout_store.set("key", "value")
    expect(RolloutKeyValueStore.find_by_key("key").value).to eq "value"
  end

  it "allows overwriting an existing key" do
    @rollout_store.set("key", "value")
    expect(RolloutKeyValueStore.find_by_key("key").value).to eq "value"
    @rollout_store.set("key", "value2")
    expect(RolloutKeyValueStore.find_by_key("key").value).to eq "value2"
  end

  it "allows getting a key that doesn't exist" do
    expect(@rollout_store.get("doesnt_exist")).to eq nil
  end

  it "allows deleting a key" do
    @rollout_store.set("key", "value")
    @rollout_store.del("key")
    expect(RolloutKeyValueStore.find_by_key("key")).to be nil
  end

  it "silently ignores deleting a key that doesn't exist" do
    @rollout_store.del("doesnt_exist") # Nothing bad should happen
  end
end
