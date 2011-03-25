class AddCommentLocale < ActiveRecord::Migration
    def self.up
        add_column :comments, :locale, :text, :null => false, :default => ""
    end

    def self.down
        remove_column :comments, :locale
    end
end

