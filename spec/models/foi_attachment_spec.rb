require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FoiAttachment, " when calculating due date" do

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
