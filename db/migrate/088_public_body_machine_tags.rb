# -*- encoding : utf-8 -*-
class PublicBodyMachineTags < ActiveRecord::Migration
  def self.up
    add_column :public_body_tags, :value, :text

    # MySQL cannot index text blobs like this
    # TODO: perhaps should change :name/:value to be a :string
    if ActiveRecord::Base.connection.adapter_name != "MySQL"
      add_index :public_body_tags, :name
    end
  end

  def self.down
    raise "No reverse migration"
    #remove_column :public_body_tags, :value
    #remove_index :public_body_tags, :name
  end
end
