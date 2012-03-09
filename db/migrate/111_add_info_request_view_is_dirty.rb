class AddInfoRequestViewIsDirty < ActiveRecord::Migration
    def self.up
        add_column :info_request, :view_is_dirty, :boolean, :default => false, :null => false
    end
    def self.down
        remove_column :info_request
    end
end



