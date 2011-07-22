class RemoveRedundantRawEmailColumns < ActiveRecord::Migration
    def self.up
        ActiveRecord::Base.connection.execute("ALTER TABLE raw_emails DROP COLUMN data_text")
        ActiveRecord::Base.connection.execute("ALTER TABLE raw_emails DROP COLUMN data_binary")
    end

    def self.down
        raise "safer not to have reverse migration scripts, and we never use them"
    end
end




