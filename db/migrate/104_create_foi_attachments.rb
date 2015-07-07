# -*- encoding : utf-8 -*-

class CreateFoiAttachments < ActiveRecord::Migration
    def self.up
        create_table :foi_attachments do |t|
            t.column :content_type, :text
            t.column :filename, :text
            t.column :charset, :text
            t.column :display_size, :text
            t.column :url_part_number, :integer
            t.column :within_rfc822_subject, :text            
            t.column :incoming_message_id, :integer
        end
    end

    def self.down
        drop_table :foi_attachments
    end
end
