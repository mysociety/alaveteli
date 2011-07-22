# == Schema Information
# Schema version: 95
#
# Table name: raw_emails
#
#  id          :integer         not null, primary key
#  data_text   :text            
#  data_binary :binary          
# - prepared to 277k.

# models/raw_email.rb:
# The fat part of models/incoming_message.rb
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: raw_email.rb,v 1.12 2009-09-17 21:10:05 francis Exp $

class RawEmail < ActiveRecord::Base
    # deliberately don't strip_attributes, so keeps raw email properly
    
    has_one :incoming_message

    before_destroy :destroy_file_representation!

    # We keep the old data_text field (which is of type text) for backwards
    # compatibility. We use the new data_binary field because only it works
    # properly in recent versions of PostgreSQL (get seg faults escaping
    # some binary strings).

    def directory
        request_id = self.incoming_message.info_request.id.to_s
        File.join(MySociety::Config.get('RAW_EMAILS_LOCATION',
                                        'files/raw_emails'), 
                  request_id[0..2], request_id)
    end

    def filepath
        File.join(self.directory, self.incoming_message.id.to_s)
    end

    def data=(d)
        if !File.exists?(self.directory)
            FileUtils.mkdir_p self.directory
        end
        File.open(self.filepath, "wb") { |file|
            file.write d
        }
    end

    def data
        if !File.exists?(self.filepath)
            dbdata
        else
            File.open(self.filepath, "rb" ).read
        end
    end

    def destroy_file_representation!
        File.delete(self.filepath)
    end

    def dbdata=(d)
        write_attribute(:data_binary, d)
    end

    def dbdata
        d = read_attribute(:data_binary)
        if !d.nil?
            return d
        end

        d = read_attribute(:data_text)
        if !d.nil?
            return d
        end

        raise "internal error, double nil value in RawEmail"
    end

end


