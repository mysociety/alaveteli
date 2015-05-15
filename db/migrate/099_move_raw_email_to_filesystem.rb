# -*- encoding : utf-8 -*-
class MoveRawEmailToFilesystem < ActiveRecord::Migration
    def self.up
        batch_size = 10
        0.step(RawEmail.count, batch_size) do |i|
            RawEmail.find(:all, :limit => batch_size, :offset => i, :order => :id).each do |raw_email|
                if !File.exists?(raw_email.filepath)
                    STDERR.puts "converting raw_email " + raw_email.id.to_s
                    raw_email.data = raw_email.dbdata
                    #raw_email.dbdata = nil
                    #raw_email.save!
                end
            end
        end
    end

    def self.down
        raise "safer not to have reverse migration scripts, and we never use them"
    end
end




