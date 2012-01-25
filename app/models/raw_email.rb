# == Schema Information
# Schema version: 108
#
# Table name: raw_emails
#
#  id :integer         not null, primary key
#

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

    # We keep the old data_text field (which is of type text) for backwards
    # compatibility. We use the new data_binary field because only it works
    # properly in recent versions of PostgreSQL (get seg faults escaping
    # some binary strings).

    def directory
        request_id = self.incoming_message.info_request.id.to_s
        if ENV["RAILS_ENV"] == "test"
            return File.join(RAILS_ROOT, 'files/raw_email_test')
        else
            return File.join(MySociety::Config.get('RAW_EMAILS_LOCATION',
                                                   'files/raw_emails'), 
                             request_id[0..2], request_id)
        end
    end

    def filepath
        File.join(self.directory, self.incoming_message.id.to_s)
    end

    def data=(d)
        if !File.exists?(self.directory)
            FileUtils.mkdir_p self.directory
        end
        File.atomic_write(self.filepath) { |file|
            file.write d
        }
    end

    def data
        File.open(self.filepath, "rb").read
    end

    def destroy_file_representation!
        File.delete(self.filepath)
    end

end


