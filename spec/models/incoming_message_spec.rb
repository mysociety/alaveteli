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

    it 'should correctly parse multipart mails with a linebreak in the boundary marker' do
        ir = info_requests(:fancy_dog_request)
        receive_incoming_mail('space-boundary.email', ir.incoming_email)
        message = ir.incoming_messages[1]
        message.mail.parts.size.should == 2
        message.mail.multipart?.should == true
    end

    it "should return the mail Date header date for sent at" do
        @im.parse_raw_email!(true)
        @im.reload
        @im.sent_at.should == @im.mail.date
    end

    it "should correctly fold various types of footer" do
        Dir.glob(File.join(RSpec.configuration.fixture_path, "files", "email-folding-example-*.txt")).each do |file|
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

    it 'should deal with GB18030 text even if the charset is missing' do
        ir = info_requests(:fancy_dog_request)
        receive_incoming_mail('no-part-charset-bad-utf8.email', ir.incoming_email)
        message = ir.incoming_messages[1]
        message.parse_raw_email!
        message.get_main_body_text_internal.should include("贵公司负责人")
    end

    it 'should not error on display of a message which has no charset set on the body part and is not good UTF-8' do
        ir = info_requests(:fancy_dog_request)
        receive_incoming_mail('no-part-charset-random-data.email', ir.incoming_email)
        message = ir.incoming_messages[1]
        message.parse_raw_email!
        message.get_main_body_text_internal.should include("The above text was badly encoded")
    end

    it 'should convert DOS-style linebreaks to Unix style' do
        ir = info_requests(:fancy_dog_request)
        receive_incoming_mail('dos-linebreaks.email', ir.incoming_email)
        message = ir.incoming_messages[1]
        message.parse_raw_email!
        message.get_main_body_text_internal.should_not match(/\r\n/)
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


    it "should load an email with funny MIME settings" do
        ActionMailer::Base.deliveries.clear
        # just send it to the holding pen
        InfoRequest.holding_pen_request.incoming_messages.size.should == 0
        receive_incoming_mail("humberside-police-odd-mime-type.email", 'dummy')
        InfoRequest.holding_pen_request.incoming_messages.size.should == 1

        # clear the notification of new message in holding pen
        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        deliveries.clear

        incoming_message = InfoRequest.holding_pen_request.incoming_messages[0]

        # This will raise an error if the bug in TMail hasn't been fixed
        incoming_message.get_body_for_html_display()
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

    it 'should fold an example lotus notes quoted part converted from HTML correctly' do
        ir = info_requests(:fancy_dog_request)
        receive_incoming_mail('lotus-notes-quoting.email', ir.incoming_email)
        message = ir.incoming_messages[1]
        message.get_main_body_text_folded.should match(/FOLDED_QUOTED_SECTION/)
    end

    it 'should fold a plain text lotus notes quoted part correctly' do
        text = "FOI Team\n\n\nInfo Requester <xxx@whatdotheyknow.com>=20\nSent by: Info Requester <request-bounce-xxxxx@whatdotheyknow.com>\n06/03/08 10:00\nPlease respond to\nInfo Requester <request-xxxx@whatdotheyknow.com>"
        @incoming_message = IncomingMessage.new()
        @incoming_message.stub_chain(:info_request, :user_name).and_return("Info Requester")
        @incoming_message.remove_lotus_quoting(text).should match(/FOLDED_QUOTED_SECTION/)
    end

    it 'should not error when trying to fold lotus notes quoted parts on a request with no user_name' do
        text = "hello"
        @incoming_message = IncomingMessage.new()
        @incoming_message.stub_chain(:info_request, :user_name).and_return(nil)
        @incoming_message.remove_lotus_quoting(text).should == 'hello'
    end

    it "cope with [ in user names properly" do
        @incoming_message = IncomingMessage.new()
        @incoming_message.stub_chain(:info_request, :user_name).and_return("Sir [ Bobble")
        # this gives a warning if [ is in the name
        text = @incoming_message.remove_lotus_quoting("Sir [ Bobble \nSent by: \n")
        text.should == "\n\nFOLDED_QUOTED_SECTION"
    end

    it 'should fold an example of another kind of forward quoting' do
        ir = info_requests(:fancy_dog_request)
        receive_incoming_mail('forward-quoting-example.email', ir.incoming_email)
        message = ir.incoming_messages[1]
        message.get_main_body_text_folded.should match(/FOLDED_QUOTED_SECTION/)
    end

    it 'should fold a further example of forward quoting' do
        ir = info_requests(:fancy_dog_request)
        receive_incoming_mail('forward-quoting-example-2.email', ir.incoming_email)
        message = ir.incoming_messages[1]
        body_text = message.get_main_body_text_folded
        body_text.should match(/FOLDED_QUOTED_SECTION/)
        # check that the quoted section incorporates both quoted messages
        body_text.should_not match('Subject: RE: Freedom of Information request')
    end

end

describe IncomingMessage, " checking validity to reply to" do
    def test_email(result, email, empty_return_path, autosubmitted = nil)
        @mail = mock('mail')
        MailHandler.stub!(:get_from_address).and_return(email)
        MailHandler.stub!(:empty_return_path?).with(@mail).and_return(empty_return_path)
        MailHandler.stub!(:get_auto_submitted).with(@mail).and_return(autosubmitted)
        @incoming_message = IncomingMessage.new()
        @incoming_message.stub!(:mail).and_return(@mail)
        @incoming_message._calculate_valid_to_reply_to.should == result
    end

    it "says a valid email is fine" do
        test_email(true, "team@mysociety.org", false)
    end

    it "says postmaster email is bad" do
        test_email(false, "postmaster@mysociety.org", false)
    end

    it "says Mailer-Daemon email is bad" do
        test_email(false, "Mailer-Daemon@mysociety.org", false)
    end

    it "says case mangled MaIler-DaemOn email is bad" do
        test_email(false, "MaIler-DaemOn@mysociety.org", false)
    end

    it "says Auto_Reply email is bad" do
        test_email(false, "Auto_Reply@mysociety.org", false)
    end

    it "says DoNotReply email is bad" do
        test_email(false, "DoNotReply@tube.tfl.gov.uk", false)
    end

    it "says a filled-out return-path is fine" do
        test_email(true, "team@mysociety.org", false)
    end

    it "says an empty return-path is bad" do
        test_email(false, "team@mysociety.org", true)
    end

    it "says an auto-submitted keyword is bad" do
        test_email(false, "team@mysociety.org", false, "auto-replied")
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

        @regex_censor_rule = CensorRule.new()
        @regex_censor_rule.text = 'm[a-z][a-z][a-z]e'
        @regex_censor_rule.regexp = true
        @regex_censor_rule.replacement = 'cat'
        @regex_censor_rule.last_edit_editor = 'unknown'
        @regex_censor_rule.last_edit_comment = 'none'
        @im.info_request.censor_rules << @regex_censor_rule
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
        data.should == "There was a xxxxx called xxxxxxx, he wished that he was xxxx."
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

        orig_text = MailHandler.get_attachment_text_one_file('application/pdf', pdf)
        orig_text.should match(/foi@tfl.gov.uk/)

        @im.binary_mask_stuff!(pdf, "application/pdf")

        masked_text = MailHandler.get_attachment_text_one_file('application/pdf', pdf)
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
        data.should == "There was a cat called Jarlsberg, he wished that he was yellow."
    end

    it "should apply hard-coded privacy rules to HTML files" do
        data = "http://#{AlaveteliConfiguration::domain}/c/cheese"
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

    it "should be able to do it at all" do
        mail = get_fixture_mail('incoming-request-bad-uuencoding.email')
        im = incoming_messages(:useless_incoming_message)
        im.stub!(:mail).and_return(mail)
        im.extract_attachments!

        im.reload
        attachments = im.foi_attachments
        attachments.size.should == 2
        attachments[1].filename.should == 'moo.txt'
        im.get_attachments_for_display.size.should == 1
    end

    it "should still work when parsed from the raw email" do
        raw_email = load_file_fixture 'inline-uuencode.email'
        mail = MailHandler.mail_from_raw_email(raw_email)
        im = incoming_messages :useless_incoming_message
        im.stub!(:raw_email).and_return(raw_email)
        im.stub!(:mail).and_return(mail)
        im.parse_raw_email!
        attachments = im.foi_attachments
        attachments.size.should == 2
    end

    it "should apply censor rules" do
        mail = get_fixture_mail('incoming-request-bad-uuencoding.email')

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

    it 'should expand an RFC822 attachment' do
        # Note that this spec will only pass using Tmail in the timezone set as datetime headers
        # are rendered out in the local time - using the Mail gem this is not necessary
        with_env_tz('London') do
            mail_body = load_file_fixture('rfc822-attachment.email')
            mail = MailHandler.mail_from_raw_email(mail_body)

            im = incoming_messages(:useless_incoming_message)
            im.stub!(:mail).and_return(mail)

            attachments = im.get_attachments_for_display
            attachments.size.should == 1
            attachment = attachments.first

            attachment.content_type.should == 'text/plain'
            attachment.filename.should == "Freedom of Information request.txt"
            attachment.charset.should == "utf-8"
            attachment.within_rfc822_subject.should == "Freedom of Information request"
            attachment.hexdigest.should == 'f10fe56e4f2287685a58b71329f09639'
        end
    end

    it "should flatten all the attachments out" do
        mail = get_fixture_mail('incoming-request-attach-attachments.email')

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

    it 'should add headers to attached plain text message bodies' do
        # Note that this spec will only pass using Tmail in the timezone set as datetime headers
        # are rendered out in the local time - using the Mail gem this is not necessary
        with_env_tz('London') do
            mail_body = load_file_fixture('incoming-request-attachment-headers.email')
            mail = MailHandler.mail_from_raw_email(mail_body)

            im = incoming_messages(:useless_incoming_message)
            im.stub!(:mail).and_return(mail)

            attachments = im.get_attachments_for_display
            attachments.size.should == 2
            attachments[0].body.should match('Date: Fri, 23 May 2008')
        end
    end

end

describe IncomingMessage, "when Outlook messages are attached to messages" do

    it "should flatten all the attachments out" do
        mail = get_fixture_mail('incoming-request-oft-attachments.email')

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

    it "should flatten all the attachments out" do
        mail = get_fixture_mail('incoming-request-tnef-attachments.email')

        im = incoming_messages(:useless_incoming_message)
        im.stub!(:mail).and_return(mail)
        im.extract_attachments!

        im.get_attachments_for_display.map(&:display_filename).should == [
            'FOI 09 02976i.doc',
            'FOI 09 02976iii.doc',
        ]
    end
end

