# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: foi_attachments
#
#  id                    :integer          not null, primary key
#  content_type          :text
#  filename              :text
#  charset               :text
#  display_size          :text
#  url_part_number       :integer
#  within_rfc822_subject :text
#  incoming_message_id   :integer
#  hexdigest             :string(32)
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FoiAttachment do

    before(:each) do
        load_raw_emails_data
    end

    it "sets the body" do
        attachment = FoiAttachment.new
        attachment.body = "baz"
        attachment.body.should == "baz"
    end
    it "sets the size" do
        attachment = FoiAttachment.new
        attachment.body = "baz"
        attachment.body.should == "baz"
        attachment.update_display_size!
        attachment.display_size.should == "0K"
    end
    it "reparses the body if it disappears" do
        im = incoming_messages(:useless_incoming_message)
        im.extract_attachments!
        main = im.get_main_body_text_part
        orig_body = main.body
        main.delete_cached_file!
        lambda {
            im.get_main_body_text_part.body
        }.should_not raise_error(Errno::ENOENT)
        main.delete_cached_file!
        main = im.get_main_body_text_part
        main.body.should == orig_body

    end
end

describe FoiAttachment, "when ensuring a filename is present" do

    it 'should create a filename for an instance with a blank filename' do
        attachment = FoiAttachment.new
        attachment.filename = ''
        attachment.ensure_filename!
        attachment.filename.should == 'attachment.bin'
    end

end
