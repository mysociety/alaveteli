require File.dirname(__FILE__) + '/../spec_helper'

describe IncomingMessage, " when dealing with incoming mail" do
    fixtures :incoming_messages, :raw_emails

    before do
        @im = incoming_messages(:useless_incoming_message)
    end

    it "should return the mail Date header date for sent at" do
        @im.sent_at.should == @im.mail.date
    end

    it "should be able to parse emails with quoted commas in" do
        em = "\"Clare College, Cambridge\" <test@test.test>"
        TMail::Address.parse(em)
    end

end


describe IncomingMessage, "when getting the attachment text" do 

  it "should not raise an error if the expansion of a zip file raises an error" do 
    mock_entry = mock('ZipFile entry', :file? => true)
    mock_entry.stub!(:get_input_stream).and_raise("invalid distance too far back")
    Zip::ZipFile.stub!(:open).and_return([mock_entry])
    IncomingMessage._get_attachment_text_internal_one_file('application/zip', "some string")
  end
  
end


describe IncomingMessage, " display attachments" do

    it "should not show slashes in filenames" do
        foi_attachment = FOIAttachment.new()
        # http://www.whatdotheyknow.com/request/post_commercial_manager_librarie#incoming-17233
        foi_attachment.filename = "FOI/09/066 RESPONSE TO FOI REQUEST RECEIVED 21st JANUARY 2009.txt"
        expected_display_filename = foi_attachment.filename.gsub(/\//, " ")
        foi_attachment.display_filename.should == expected_display_filename
    end

    it "should not show slashes in subject generated filenames" do
        foi_attachment = FOIAttachment.new()
        # http://www.whatdotheyknow.com/request/post_commercial_manager_librarie#incoming-17233
        foi_attachment.within_rfc822_subject = "FOI/09/066 RESPONSE TO FOI REQUEST RECEIVED 21st JANUARY 2009"
        foi_attachment.content_type = 'text/plain'
        expected_display_filename = foi_attachment.within_rfc822_subject.gsub(/\//, " ") + ".txt"
        foi_attachment.display_filename.should == expected_display_filename
    end

end

describe IncomingMessage, " folding quoted parts of emails" do

    it "cope with [ in user names properly" do
        @user = mock_model(User)
        @user.stub!(:name).and_return("Sir [ Bobble")
        @info_request = mock_model(InfoRequest)
        @info_request.stub!(:user).and_return(@user)

        @incoming_message = IncomingMessage.new()
        @incoming_message.info_request = @info_request

        # this gives a warning if [ is in the name
        text = @incoming_message.remove_lotus_quoting("Sir [ Bobble \nSent by: \n")
        text.should == "\n\nFOLDED_QUOTED_SECTION"
    end

end

describe IncomingMessage, " checking validity to reply to" do
    def test_email(email, result)
        @address = mock(TMail::Address)
        @address.stub!(:spec).and_return(email)
        @mail = mock(TMail::Mail)
        @mail.stub!(:from_addrs).and_return( [ @address ] )
        @incoming_message = IncomingMessage.new()
        @incoming_message.stub!(:mail).and_return(@mail)

        @incoming_message.valid_to_reply_to?.should == result
    end

    it "says a valid email is fine" do
        test_email("team@mysociety.org", true)
    end

    it "says postmaster email is bad" do
        test_email("postmaster@mysociety.org", false)
    end

    it "says Mailer-Daemon email is bad" do
        test_email("Mailer-Daemon@mysociety.org", false)
    end

    it "says case mangled MaIler-DaemOn email is bad" do
        test_email("MaIler-DaemOn@mysociety.org", false)
    end

    it "says Auto_Reply email is bad" do
        test_email("Auto_Reply@mysociety.org", false)
    end

    it "says DoNotReply email is bad" do
        test_email("DoNotReply@tube.tfl.gov.uk", false)
    end

end

describe IncomingMessage, " when censoring data" do
    fixtures :incoming_messages, :raw_emails, :public_bodies, :info_requests, :users

    before do
        @test_data = "There was a mouse called Stilton, he wished that he was blue."

        @im = incoming_messages(:useless_incoming_message)

        @censor_rule_1 = CensorRule.new()
        @censor_rule_1.text = "Stilton"
        @censor_rule_1.replacement = "Jarlsberg"
        @censor_rule_1.last_edit_editor = "unknown"
        @censor_rule_1.last_edit_comment = "none"
        @im.info_request.censor_rules << @censor_rule_1

        @censor_rule_2 = CensorRule.new()
        @censor_rule_2.text = "blue"
        @censor_rule_2.replacement = "yellow"
        @censor_rule_2.last_edit_editor = "unknown"
        @censor_rule_2.last_edit_comment = "none"
        @im.info_request.censor_rules << @censor_rule_2
    end

    it "should do nothing to a JPEG" do
        data = @test_data.dup
        @im.binary_mask_stuff!(data, "image/jpeg")
        data.should == @test_data
    end

    it "should replace censor text in Word documents" do
        data = @test_data.dup
        @im.binary_mask_stuff!(data, "application/vnd.ms-word")
        data.should == "There was a mouse called xxxxxxx, he wished that he was xxxx."
    end

    it "should replace ASCII email addresses in Word documents" do
        orig_data = "His email was foo@bar.com"
        data = orig_data.dup
        @im.binary_mask_stuff!(data, "application/vnd.ms-word")
        data.should == "His email was xxx@xxx.xxx"
    end

    it "should replace UCS-2 addresses in Word documents" do
        orig_data = "His email was f\000o\000o\000@\000b\000a\000r\000.\000c\000o\000m\000, indeed"
        data = orig_data.dup
        @im.binary_mask_stuff!(data, "application/vnd.ms-word")
        data.should == "His email was x\000x\000x\000@\000x\000x\000x\000.\000x\000x\000x\000, indeed"
    end

    # As at March 9th 2010: This test fails with pdftk 1.41+dfsg-1 installed
    # which is in Ubuntu Karmic. It works again for the lasest version
    # 1.41+dfsg-7 in Debian unstable. And it works for Debian stable.
    it "should replace everything in PDF files" do
        orig_pdf = load_file_fixture('tfl.pdf')
        pdf = orig_pdf.dup

        orig_text = IncomingMessage._get_attachment_text_internal_one_file('application/pdf', pdf)
        orig_text.should match(/foi@tfl.gov.uk/)

        @im.binary_mask_stuff!(pdf, "application/pdf")

        masked_text = IncomingMessage._get_attachment_text_internal_one_file('application/pdf', pdf)
        masked_text.should_not match(/foi@tfl.gov.uk/)
        masked_text.should match(/xxx@xxx.xxx.xx/)
    end

    it "should not produce zero length output if pdftk silently fails" do
        orig_pdf = load_file_fixture('psni.pdf')
        pdf = orig_pdf.dup
        @im.binary_mask_stuff!(pdf, "application/pdf")
        pdf.should_not == ""
    end

    it "should apply censor rules to HTML files" do
        data = @test_data.dup
        @im.html_mask_stuff!(data)
        data.should == "There was a mouse called Jarlsberg, he wished that he was yellow."
    end

    it "should apply censor rules to From: addresses" do
        mock_mail = mock('Email object')
        mock_mail.stub!(:from_name_if_present).and_return("Stilton Mouse")
        @im.stub!(:mail).and_return(mock_mail)
        
        safe_mail_from = @im.safe_mail_from
        safe_mail_from.should == "Jarlsberg Mouse"
    end

end

describe IncomingMessage, " when censoring whole users" do
    fixtures :incoming_messages, :raw_emails, :public_bodies, :info_requests, :users

    before do
        @test_data = "There was a mouse called Stilton, he wished that he was blue."

        @im = incoming_messages(:useless_incoming_message)

        @censor_rule_1 = CensorRule.new()
        @censor_rule_1.text = "Stilton"
        @censor_rule_1.replacement = "Gorgonzola"
        @censor_rule_1.last_edit_editor = "unknown"
        @censor_rule_1.last_edit_comment = "none"
        @im.info_request.user.censor_rules << @censor_rule_1
    end

    it "should apply censor rules to HTML files" do
        data = @test_data.dup
        @im.html_mask_stuff!(data)
        data.should == "There was a mouse called Jarlsberg, he wished that he was blue."
    end

    it "should replace censor text to Word documents" do
        data = @test_data.dup
        @im.binary_mask_stuff!(data, "application/vnd.ms-word")
        data.should == "There was a mouse called xxxxxxx, he wished that he was xxxx."
    end
end


describe IncomingMessage, " when uudecoding bad messages" do
    it "should be able to do it at all" do
        mail_body = load_file_fixture('incoming-request-bad-uuencoding.email')
        mail = TMail::Mail.parse(mail_body)
        mail.base64_decode

        im = IncomingMessage.new
        im.stub!(:mail).and_return(mail)
        ir = InfoRequest.new
        im.info_request = ir
        u = User.new
        ir.user = u

        attachments = im.get_main_body_text_uudecode_attachments
        attachments.size.should == 1
        attachments[0].filename.should == 'moo.txt'
    end

    it "should apply censor rules" do
        mail_body = load_file_fixture('incoming-request-bad-uuencoding.email')
        mail = TMail::Mail.parse(mail_body)
        mail.base64_decode

        im = IncomingMessage.new
        im.stub!(:mail).and_return(mail)
        ir = InfoRequest.new
        im.info_request = ir
        u = User.new
        ir.user = u

        @censor_rule = CensorRule.new()
        @censor_rule.text = "moo"
        @censor_rule.replacement = "bah"
        @censor_rule.last_edit_editor = "unknown"
        @censor_rule.last_edit_comment = "none"
        ir.censor_rules << @censor_rule

        attachments = im.get_main_body_text_uudecode_attachments
        attachments.size.should == 1
        attachments[0].filename.should == 'bah.txt'
    end

end

describe IncomingMessage, "when messages are attached to messages" do
    it "should flatten all the attachments out" do
        mail_body = load_file_fixture('incoming-request-attach-attachments.email')
        mail = TMail::Mail.parse(mail_body)
        mail.base64_decode

        im = IncomingMessage.new
        im.stub!(:mail).and_return(mail)
        ir = InfoRequest.new
        im.info_request = ir
        u = User.new
        ir.user = u

        attachments = im.get_attachments_for_display
        attachments.size.should == 3
        attachments[0].display_filename.should == 'Same attachment twice.txt'
        attachments[1].display_filename.should == 'hello.txt'
        attachments[2].display_filename.should == 'hello.txt'
    end
end

describe IncomingMessage, "when Outlook messages are attached to messages" do
    it "should flatten all the attachments out" do
        mail_body = load_file_fixture('incoming-request-oft-attachments.email')
        mail = TMail::Mail.parse(mail_body)
        mail.base64_decode

        im = IncomingMessage.new
        im.stub!(:mail).and_return(mail)
        ir = InfoRequest.new
        im.info_request = ir
        u = User.new
        ir.user = u

        attachments = im.get_attachments_for_display
        attachments.size.should == 2
        attachments[0].display_filename.should == 'test.html' # picks HTML rather than text by default, as likely to render better
        attachments[1].display_filename.should == 'attach.txt'
    end
end

describe IncomingMessage, "when TNEF attachments are attached to messages" do
    it "should flatten all the attachments out" do
        mail_body = load_file_fixture('incoming-request-tnef-attachments.email')
        mail = TMail::Mail.parse(mail_body)
        mail.base64_decode

        im = IncomingMessage.new
        im.stub!(:mail).and_return(mail)
        ir = InfoRequest.new
        im.info_request = ir
        u = User.new
        ir.user = u

        attachments = im.get_attachments_for_display
        attachments.size.should == 2
        attachments[0].display_filename.should == 'FOI 09 02976i.doc'
        attachments[1].display_filename.should == 'FOI 09 02976iii.doc'
    end
end



