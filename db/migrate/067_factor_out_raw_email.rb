# -*- encoding : utf-8 -*-
class FactorOutRawEmail < ActiveRecord::Migration
    def self.up
        create_table :raw_emails do |t|
            t.column :data, :text, :null => false
        end

        add_column :incoming_messages, :raw_email_id, :integer, :null => true
        change_column :incoming_messages, :raw_data, :text, :null => true

        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "ALTER TABLE incoming_messages ADD CONSTRAINT fk_incoming_messages_raw_email FOREIGN KEY (raw_email_id) REFERENCES raw_emails(id)"
        end

        batch_size = 10
        0.step(IncomingMessage.count, batch_size) do |i|
            IncomingMessage.find(:all, :limit => batch_size, :offset => i, :order => :id).each do |incoming_message|
                if incoming_message.raw_email_id.nil?
                    STDERR.puts "doing incoming_message id " + incoming_message.id.to_s
                    ActiveRecord::Base.transaction do
                        raw_email = RawEmail.new
                        raw_email.data = incoming_message.raw_data
                        incoming_message.raw_email = raw_email
                        incoming_message.raw_data = nil
                        raw_email.save!
                        incoming_message.save!
                    end
                end
            end
        end

        change_column :incoming_messages, :raw_email_id, :integer, :null => false
        remove_column :incoming_messages, :raw_data
    end

    def self.down
        raise "down migration not implemented"
    end
end
