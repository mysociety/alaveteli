class MoveRawEmailToFilesystem < ActiveRecord::Migration[4.2] # 2.3
  def self.up
    RawEmail.find_each(batch_size: 10) do |raw_email|
      unless File.exist?(raw_email.filepath)
        STDERR.puts "converting raw_email #{raw_email.id.to_s}"
        raw_email.data = raw_email.dbdata
      end
    end
  end

  def self.down
    raise "safer not to have reverse migration scripts, and we never use them"
  end
end
