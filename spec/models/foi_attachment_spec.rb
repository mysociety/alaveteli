require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FoiAttachment, " when calculating due date" do
    fixtures :incoming_messages, :raw_emails, :public_bodies, :public_body_translations, :info_requests, :users, :foi_attachments

    before(:each) do
        load_raw_emails_data(raw_emails)
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
        mail_body = load_file_fixture('incoming-request-attach-attachments.email')
        mail = TMail::Mail.parse(mail_body)
        mail.base64_decode
        im = incoming_messages(:useless_incoming_message)
        im.stub!(:mail).and_return(mail)        
        #im.extract_attachments!
        attachments = im.get_attachments_for_display
        FileUtils.rm attachments[0].filepath
        lambda {
            attachments = im.get_attachments_for_display
            body = attachments[0].body
        }.should_not raise_error(Errno::ENOENT)
    end
end
