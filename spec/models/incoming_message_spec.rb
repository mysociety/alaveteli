# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe IncomingMessage, " when dealing with incoming mail" do

    before(:each) do
        @im = incoming_messages(:useless_incoming_message)
        load_raw_emails_data
    end

    after(:all) do
        ActionMailer::Base.deliveries.clear
    end

    it "should return the mail Date header date for sent at" do
        @im.parse_raw_email!(true)
        @im.reload
        @im.sent_at.should == @im.mail.date
    end

    it "should be able to parse emails with quoted commas in" do
        em = "\"Clare College, Cambridge\" <test@test.test>"
        TMail::Address.parse(em)
    end

    it "should correctly fold various types of footer" do
        Dir.glob(File.join(Spec::Runner.configuration.fixture_path, "files", "email-folding-example-*.txt")).each do |file|
            message = File.read(file)
            parsed = IncomingMessage.remove_quoted_sections(message)
            expected = File.read("#{file}.expected")
            parsed.should include(expected)
        end
    end

    it "should ensure cached body text has been parsed correctly" do
        ir = info_requests(:fancy_dog_request)
        receive_incoming_mail('quoted-subject-iso8859-1.email', ir.incoming_email)
        message = ir.incoming_messages[1]
        message.get_main_body_text_unfolded.should_not include("Email has no body")
    end

    it "should correctly convert HTML even when there's a meta tag asserting that it is iso-8859-1 which would normally confuse elinks" do
        ir = info_requests(:fancy_dog_request)
        receive_incoming_mail('quoted-subject-iso8859-1.email', ir.incoming_email)
        message = ir.incoming_messages[1]
        message.parse_raw_email!
        message.get_main_body_text_part.charset.should == "iso-8859-1"
        message.get_main_body_text_internal.should include("política")
    end

    it "should unquote RFC 2047 headers" do
        ir = info_requests(:fancy_dog_request)
        receive_incoming_mail('quoted-subject-iso8859-1.email', ir.incoming_email)
        message = ir.incoming_messages[1]
        message.mail_from.should == "Coordenação de Relacionamento, Pesquisa e Informação/CEDI"
        message.subject.should == "Câmara Responde:  Banco de ideias"
    end


    it "should fold multiline sections" do
      {
        "foo\n--------\nconfidential"                                       => "foo\nFOLDED_QUOTED_SECTION\n", # basic test
        "foo\n--------\nbar - confidential"                                 => "foo\nFOLDED_QUOTED_SECTION\n", # allow scorechar inside folded section
        "foo\n--------\nbar\n--------\nconfidential"                        => "foo\n--------\nbar\nFOLDED_QUOTED_SECTION\n", # don't assume that anything after a score is a folded section
        "foo\n--------\nbar\n--------\nconfidential\n--------\nrest"        => "foo\n--------\nbar\nFOLDED_QUOTED_SECTION\nrest", # don't assume that a folded section continues to the end of the message
        "foo\n--------\nbar\n- - - - - - - -\nconfidential\n--------\nrest" => "foo\n--------\nbar\nFOLDED_QUOTED_SECTION\nrest", # allow spaces in the score
      }.each do |input,output|
        IncomingMessage.remove_quoted_sections(input).should == output
      end
    end

end

describe IncomingMessage, "when parsing HTML mail" do 
    it "should display UTF-8 characters in the plain text version correctly" do
        html = "<html><b>foo</b> është"
        plain_text = IncomingMessage._get_attachment_text_internal_one_file('text/html', html)
        plain_text.should match(/është/)
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
        foi_attachment = FoiAttachment.new()
        # http://www.whatdotheyknow.com/request/post_commercial_manager_librarie#incoming-17233
        foi_attachment.filename = "FOI/09/066 RESPONSE TO FOI REQUEST RECEIVED 21st JANUARY 2009.txt"
        expected_display_filename = foi_attachment.filename.gsub(/\//, " ")
        foi_attachment.display_filename.should == expected_display_filename
    end

    it "should not show slashes in subject generated filenames" do
        foi_attachment = FoiAttachment.new()
        # http://www.whatdotheyknow.com/request/post_commercial_manager_librarie#incoming-17233
        foi_attachment.within_rfc822_subject = "FOI/09/066 RESPONSE TO FOI REQUEST RECEIVED 21st JANUARY 2009"
        foi_attachment.content_type = 'text/plain'
        foi_attachment.ensure_filename!
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
    def test_email(result, email, return_path, autosubmitted = nil)
        @address = mock(TMail::Address)
        @address.stub!(:spec).and_return(email)

        @return_path = mock(TMail::ReturnPathHeader)
        @return_path.stub!(:addr).and_return(return_path)
        if !autosubmitted.nil?
            @autosubmitted = TMail::UnstructuredHeader.new("auto-submitted", autosubmitted)
        end
        @mail = mock(TMail::Mail)
        @mail.stub!(:from_addrs).and_return( [ @address ] )
        @mail.stub!(:[]).with("return-path").and_return(@return_path)
        @mail.stub!(:[]).with("auto-submitted").and_return(@autosubmitted)

        @incoming_message = IncomingMessage.new()
        @incoming_message.stub!(:mail).and_return(@mail)
        @incoming_message._calculate_valid_to_reply_to.should == result
    end

    it "says a valid email is fine" do
        test_email(true, "team@mysociety.org", nil)
    end

    it "says postmaster email is bad" do
        test_email(false, "postmaster@mysociety.org", nil)
    end

    it "says Mailer-Daemon email is bad" do
        test_email(false, "Mailer-Daemon@mysociety.org", nil)
    end

    it "says case mangled MaIler-DaemOn email is bad" do
        test_email(false, "MaIler-DaemOn@mysociety.org", nil)
    end

    it "says Auto_Reply email is bad" do
        test_email(false, "Auto_Reply@mysociety.org", nil)
    end

    it "says DoNotReply email is bad" do
        test_email(false, "DoNotReply@tube.tfl.gov.uk", nil)
    end

    it "says a filled-out return-path is fine" do
        test_email(true, "team@mysociety.org", "Return-path: <foo@baz.com>")
    end

    it "says an empty return-path is bad" do
        test_email(false, "team@mysociety.org", "<>")
    end

    it "says an auto-submitted keyword is bad" do
        test_email(false, "team@mysociety.org", nil, "auto-replied")
    end

end

describe IncomingMessage, " checking validity to reply to with real emails" do

    after(:all) do
        ActionMailer::Base.deliveries.clear
    end
    it "should allow a reply to plain emails" do
        ir = info_requests(:fancy_dog_request) 
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)
        ir.incoming_messages[1].valid_to_reply_to?.should == true
    end
    it "should not allow a reply to emails with empty return-paths" do
        ir = info_requests(:fancy_dog_request) 
        receive_incoming_mail('empty-return-path.email', ir.incoming_email)
        ir.incoming_messages[1].valid_to_reply_to?.should == false
    end
    it "should not allow a reply to emails with autoresponse headers" do
        ir = info_requests(:fancy_dog_request) 
        receive_incoming_mail('autoresponse-header.email', ir.incoming_email)
        ir.incoming_messages[1].valid_to_reply_to?.should == false
    end

end

describe IncomingMessage, " when censoring data" do

    before(:each) do
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

        load_raw_emails_data
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



    def pdf_replacement_test(use_ghostscript_compression)
        config = MySociety::Config.load_default()
        previous = config['USE_GHOSTSCRIPT_COMPRESSION']
        config['USE_GHOSTSCRIPT_COMPRESSION'] = use_ghostscript_compression
        orig_pdf = load_file_fixture('tfl.pdf')
        pdf = orig_pdf.dup

        orig_text = IncomingMessage._get_attachment_text_internal_one_file('application/pdf', pdf)
        orig_text.should match(/foi@tfl.gov.uk/)

        @im.binary_mask_stuff!(pdf, "application/pdf")

        masked_text = IncomingMessage._get_attachment_text_internal_one_file('application/pdf', pdf)
        masked_text.should_not match(/foi@tfl.gov.uk/)
        masked_text.should match(/xxx@xxx.xxx.xx/)
        config['USE_GHOSTSCRIPT_COMPRESSION'] = previous
    end

    it "should replace everything in PDF files using pdftk" do
        pdf_replacement_test(false)
    end

    it "should replace everything in PDF files using ghostscript" do
        pdf_replacement_test(true)
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

    it "should apply hard-coded privacy rules to HTML files" do
        domain = MySociety::Config.get('DOMAIN')
        data = "http://#{domain}/c/cheese"
        @im.html_mask_stuff!(data)
        data.should == "[WDTK login link]"
    end

    it "should apply censor rules to From: addresses" do
        @im.stub!(:mail_from).and_return("Stilton Mouse")        
        @im.stub!(:last_parsed).and_return(Time.now)        
        safe_mail_from = @im.safe_mail_from
        safe_mail_from.should == "Jarlsberg Mouse"
    end

end

describe IncomingMessage, " when censoring whole users" do

    before(:each) do
        @test_data = "There was a mouse called Stilton, he wished that he was blue."

        @im = incoming_messages(:useless_incoming_message)

        @censor_rule_1 = CensorRule.new()
        @censor_rule_1.text = "Stilton"
        @censor_rule_1.replacement = "Gorgonzola"
        @censor_rule_1.last_edit_editor = "unknown"
        @censor_rule_1.last_edit_comment = "none"
        @im.info_request.user.censor_rules << @censor_rule_1
        load_raw_emails_data
    end

    it "should apply censor rules to HTML files" do
        data = @test_data.dup
        @im.html_mask_stuff!(data)
        data.should == "There was a mouse called Gorgonzola, he wished that he was blue."
    end

    it "should replace censor text to Word documents" do
        data = @test_data.dup
        @im.binary_mask_stuff!(data, "application/vnd.ms-word")
        data.should == "There was a mouse called xxxxxxx, he wished that he was blue."
    end
end


describe IncomingMessage, " when uudecoding bad messages" do

    before(:each) do
        load_raw_emails_data
    end

    it "should be able to do it at all" do
        mail_body = load_file_fixture('incoming-request-bad-uuencoding.email')
        mail = TMail::Mail.parse(mail_body)
        mail.base64_decode
        im = incoming_messages(:useless_incoming_message)
        im.stub!(:mail).and_return(mail)
        im.extract_attachments!
        
        attachments = im.foi_attachments
        attachments.size.should == 2
        attachments[1].filename.should == 'moo.txt'
        im.get_attachments_for_display.size.should == 1
    end

    it "should apply censor rules" do
        mail_body = load_file_fixture('incoming-request-bad-uuencoding.email')
        mail = TMail::Mail.parse(mail_body)
        mail.base64_decode

        im = incoming_messages(:useless_incoming_message)
        im.stub!(:mail).and_return(mail)
        ir = info_requests(:fancy_dog_request)

        @censor_rule = CensorRule.new()
        @censor_rule.text = "moo"
        @censor_rule.replacement = "bah"
        @censor_rule.last_edit_editor = "unknown"
        @censor_rule.last_edit_comment = "none"
        ir.censor_rules << @censor_rule
        im.extract_attachments!

        im.get_attachments_for_display.map(&:display_filename).should == [
            'bah.txt',
        ]
    end

end

describe IncomingMessage, "when messages are attached to messages" do

    before(:each) do
        load_raw_emails_data
    end

    it "should flatten all the attachments out" do
        mail_body = load_file_fixture('incoming-request-attach-attachments.email')
        mail = TMail::Mail.parse(mail_body)
        mail.base64_decode

        im = incoming_messages(:useless_incoming_message)
        im.stub!(:mail).and_return(mail)
        
        im.extract_attachments!

        attachments = im.get_attachments_for_display
        attachments.map(&:display_filename).should == [
            'Same attachment twice.txt',
            'hello.txt',
            'hello.txt',
        ]
    end
end

describe IncomingMessage, "when Outlook messages are attached to messages" do

    before(:each) do
        load_raw_emails_data
    end

    it "should flatten all the attachments out" do
        mail_body = load_file_fixture('incoming-request-oft-attachments.email')
        mail = TMail::Mail.parse(mail_body)
        mail.base64_decode

        im = incoming_messages(:useless_incoming_message)
        im.stub!(:mail).and_return(mail)
        im.extract_attachments!

        im.get_attachments_for_display.map(&:display_filename).should == [
            'test.html',  # picks HTML rather than text by default, as likely to render better
            'attach.txt',
        ]
    end
end

describe IncomingMessage, "when TNEF attachments are attached to messages" do

    before(:each) do
        load_raw_emails_data
    end

    it "should flatten all the attachments out" do
        mail_body = load_file_fixture('incoming-request-tnef-attachments.email')
        mail = TMail::Mail.parse(mail_body)
        mail.base64_decode

        im = incoming_messages(:useless_incoming_message)
        im.stub!(:mail).and_return(mail)
        im.extract_attachments!

        im.get_attachments_for_display.map(&:display_filename).should == [
            'FOI 09 02976i.doc',
            'FOI 09 02976iii.doc',
        ]
    end
end

