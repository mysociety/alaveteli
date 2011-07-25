class RemoveRedundantRawEmailColumns < ActiveRecord::Migration
    def self.up
        remove_column :raw_emails, :data_text
    end
    def self.down
        add_column :raw_emails, :data_text, :text
    end
end




