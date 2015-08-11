# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: incoming_messages
#
#  id                             :integer          not null, primary key
#  info_request_id                :integer          not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  raw_email_id                   :integer          not null
#  cached_attachment_text_clipped :text
#  cached_main_body_text_folded   :text
#  cached_main_body_text_unfolded :text
#  subject                        :text
#  mail_from_domain               :text
#  valid_to_reply_to              :boolean
#  last_parsed                    :datetime
#  mail_from                      :text
#  sent_at                        :datetime
#  prominence                     :string(255)      default("normal"), not null
#  prominence_reason              :text
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe IncomingMessage, 'when validating' do

  it 'should be valid with valid prominence values' do
    ['hidden', 'requester_only', 'normal'].each do |prominence|
      incoming_message = IncomingMessage.new(:raw_email => RawEmail.new,
                                             :info_request => InfoRequest.new,
                                             :prominence => prominence)
      expect(incoming_message.valid?).to be true
    end
  end

  it 'should not be valid with an invalid prominence value' do
    incoming_message = IncomingMessage.new(:raw_email => RawEmail.new,
                                           :info_request => InfoRequest.new,
                                           :prominence => 'norman')
    expect(incoming_message.valid?).to be false
  end

end

describe IncomingMessage, 'when getting a response event' do

  it 'should return an event with event_type "response"' do
    incoming_message = IncomingMessage.new
    ['comment', 'response'].each do |event_type|
      incoming_message.info_request_events << InfoRequestEvent.new(:event_type => event_type)
    end
    expect(incoming_message.response_event.event_type).to eq('response')
  end

end

describe IncomingMessage, 'when asked if a user can view it' do

  before do
    @user = mock_model(User)
    @info_request = mock_model(InfoRequest)
    @incoming_message = IncomingMessage.new(:info_request => @info_request)
  end

  context 'if the prominence is hidden' do

    before do
      @incoming_message.prominence = 'hidden'
    end

    it 'should return true if the user can view hidden things' do
      allow(User).to receive(:view_hidden?).with(@user).and_return(true)
      expect(@incoming_message.user_can_view?(@user)).to be true
    end

    it 'should return false if the user cannot view hidden things' do
      allow(User).to receive(:view_hidden?).with(@user).and_return(false)
      expect(@incoming_message.user_can_view?(@user)).to be false
    end

  end

  context 'if the prominence is requester_only' do

    before do
      @incoming_message.prominence = 'requester_only'
    end

    it 'should return true if the user owns the associated request' do
      allow(@info_request).to receive(:is_owning_user?).with(@user).and_return(true)
      expect(@incoming_message.user_can_view?(@user)).to be true
    end

    it 'should return false if the user does not own the associated request' do
      allow(@info_request).to receive(:is_owning_user?).with(@user).and_return(false)
      expect(@incoming_message.user_can_view?(@user)).to be false
    end
  end

  context 'if the prominence is normal' do

    before do
      @incoming_message.prominence = 'normal'
    end

    it 'should return true' do
      expect(@incoming_message.user_can_view?(@user)).to be true
    end

  end

end

describe 'when destroying a message' do

  before do
    @incoming_message = FactoryGirl.create(:plain_incoming_message)
  end

  it 'can destroy a message with more than one info request event' do
    @info_request = @incoming_message.info_request
    @info_request.log_event('response',
                            :incoming_message_id => @incoming_message.id)
    @info_request.log_event('edit_incoming',
                            :incoming_message_id => @incoming_message.id)
    @incoming_message.fully_destroy
    expect(IncomingMessage.where(:id => @incoming_message.id)).to be_empty
  end

end

describe 'when asked if it is indexed by search' do

  before do
    @incoming_message = IncomingMessage.new
  end

  it 'should return false if it has prominence "hidden"' do
    @incoming_message.prominence = 'hidden'
    expect(@incoming_message.indexed_by_search?).to be false
  end

  it 'should return false if it has prominence "requester_only"' do
    @incoming_message.prominence = 'requester_only'
    expect(@incoming_message.indexed_by_search?).to be false
  end

  it 'should return true if it has prominence "normal"' do
    @incoming_message.prominence = 'normal'
    expect(@incoming_message.indexed_by_search?).to be true
  end

end

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
    expect(message.mail.parts.size).to eq(2)
    expect(message.mail.multipart?).to eq(true)
  end

  it "should return the mail Date header date for sent at" do
    @im.parse_raw_email!(true)
    @im.reload
    expect(@im.sent_at).to eq(@im.mail.date)
  end

  it "should correctly fold various types of footer" do
    Dir.glob(File.join(RSpec.configuration.fixture_path, "files", "email-folding-example-*.txt")).each do |file|
      message = File.read(file)
      parsed = IncomingMessage.remove_quoted_sections(message)
      expected = File.read("#{file}.expected")
      expect(parsed).to be_equal_modulo_whitespace_to expected
    end
  end

  it "should ensure cached body text has been parsed correctly" do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('quoted-subject-iso8859-1.email', ir.incoming_email)
    message = ir.incoming_messages[1]
    expect(message.get_main_body_text_unfolded).not_to include("Email has no body")
  end

  it "should correctly convert HTML even when there's a meta tag asserting that it is iso-8859-1 which would normally confuse elinks" do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('quoted-subject-iso8859-1.email', ir.incoming_email)
    message = ir.incoming_messages[1]
    message.parse_raw_email!
    expect(message.get_main_body_text_part.charset).to eq("iso-8859-1")
    expect(message.get_main_body_text_internal).to include("política")
  end

  it "should unquote RFC 2047 headers" do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('quoted-subject-iso8859-1.email', ir.incoming_email)
    message = ir.incoming_messages[1]
    expect(message.mail_from).to eq("Coordenação de Relacionamento, Pesquisa e Informação/CEDI")
    expect(message.subject).to eq("Câmara Responde:  Banco de ideias")
  end

  it 'should deal with GB18030 text even if the charset is missing' do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('no-part-charset-bad-utf8.email', ir.incoming_email)
    message = ir.incoming_messages[1]
    message.parse_raw_email!
    expect(message.get_main_body_text_internal).to include("贵公司负责人")
  end

  it 'should not error on display of a message which has no charset set on the body part and is not good UTF-8' do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('no-part-charset-random-data.email', ir.incoming_email)
    message = ir.incoming_messages[1]
    message.parse_raw_email!
    expect(message.get_main_body_text_internal).to include("The above text was badly encoded")
  end

  it 'should convert DOS-style linebreaks to Unix style' do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('dos-linebreaks.email', ir.incoming_email)
    message = ir.incoming_messages[1]
    message.parse_raw_email!
    expect(message.get_main_body_text_internal).not_to match(/\r\n/)
  end

  it "should fold multiline sections" do
    {
      "foo\n--------\nconfidential"                                       => "foo\nFOLDED_QUOTED_SECTION\n", # basic test
      "foo\n--------\nbar - confidential"                                 => "foo\nFOLDED_QUOTED_SECTION\n", # allow scorechar inside folded section
      "foo\n--------\nbar\n--------\nconfidential"                        => "foo\n--------\nbar\nFOLDED_QUOTED_SECTION\n", # don't assume that anything after a score is a folded section
      "foo\n--------\nbar\n--------\nconfidential\n--------\nrest"        => "foo\n--------\nbar\nFOLDED_QUOTED_SECTION\nrest", # don't assume that a folded section continues to the end of the message
      "foo\n--------\nbar\n- - - - - - - -\nconfidential\n--------\nrest" => "foo\n--------\nbar\nFOLDED_QUOTED_SECTION\nrest", # allow spaces in the score
    }.each do |input,output|
      expect(IncomingMessage.remove_quoted_sections(input)).to eq(output)
    end
  end


  it "should load an email with funny MIME settings" do
    ActionMailer::Base.deliveries.clear
    # just send it to the holding pen
    expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(0)
    receive_incoming_mail("humberside-police-odd-mime-type.email", 'dummy')
    expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(1)

    # clear the notification of new message in holding pen
    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(1)
    deliveries.clear

    incoming_message = InfoRequest.holding_pen_request.incoming_messages[0]

    # This will raise an error if the bug in TMail hasn't been fixed
    incoming_message.get_body_for_html_display
  end


  it 'should handle a main body part that is just quoted content in an email that has
        no subject' do
    i = IncomingMessage.new
    allow(i).to receive(:get_main_body_text_unfolded).and_return("some quoting")
    allow(i).to receive(:get_main_body_text_folded).and_return("FOLDED_QUOTED_SECTION")
    allow(i).to receive(:subject).and_return(nil)
    i.get_body_for_html_display
  end


end

describe IncomingMessage, " display attachments" do

  it "should not show slashes in filenames" do
    foi_attachment = FoiAttachment.new
    # http://www.whatdotheyknow.com/request/post_commercial_manager_librarie#incoming-17233
    foi_attachment.filename = "FOI/09/066 RESPONSE TO FOI REQUEST RECEIVED 21st JANUARY 2009.txt"
    expected_display_filename = foi_attachment.filename.gsub(/\//, " ")
    expect(foi_attachment.display_filename).to eq(expected_display_filename)
  end

  it "should not show slashes in subject generated filenames" do
    foi_attachment = FoiAttachment.new
    # http://www.whatdotheyknow.com/request/post_commercial_manager_librarie#incoming-17233
    foi_attachment.within_rfc822_subject = "FOI/09/066 RESPONSE TO FOI REQUEST RECEIVED 21st JANUARY 2009"
    foi_attachment.content_type = 'text/plain'
    foi_attachment.ensure_filename!
    expected_display_filename = foi_attachment.within_rfc822_subject.gsub(/\//, " ") + ".txt"
    expect(foi_attachment.display_filename).to eq(expected_display_filename)
  end

end

describe IncomingMessage, " folding quoted parts of emails" do

  it 'should fold an example lotus notes quoted part converted from HTML correctly' do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('lotus-notes-quoting.email', ir.incoming_email)
    message = ir.incoming_messages[1]
    expect(message.get_main_body_text_folded).to match(/FOLDED_QUOTED_SECTION/)
  end

  it 'should fold a plain text lotus notes quoted part correctly' do
    text = "FOI Team\n\n\nInfo Requester <xxx@whatdotheyknow.com>=20\nSent by: Info Requester <request-bounce-xxxxx@whatdotheyknow.com>\n06/03/08 10:00\nPlease respond to\nInfo Requester <request-xxxx@whatdotheyknow.com>"
    @incoming_message = IncomingMessage.new
    allow(@incoming_message).to receive_message_chain(:info_request, :user_name).and_return("Info Requester")
    expect(@incoming_message.remove_lotus_quoting(text)).to match(/FOLDED_QUOTED_SECTION/)
  end

  it 'should not error when trying to fold lotus notes quoted parts on a request with no user_name' do
    text = "hello"
    @incoming_message = IncomingMessage.new
    allow(@incoming_message).to receive_message_chain(:info_request, :user_name).and_return(nil)
    expect(@incoming_message.remove_lotus_quoting(text)).to eq('hello')
  end

  it "cope with [ in user names properly" do
    @incoming_message = IncomingMessage.new
    allow(@incoming_message).to receive_message_chain(:info_request, :user_name).and_return("Sir [ Bobble")
    # this gives a warning if [ is in the name
    text = @incoming_message.remove_lotus_quoting("Sir [ Bobble \nSent by: \n")
    expect(text).to eq("\n\nFOLDED_QUOTED_SECTION")
  end

  it 'should fold an example of another kind of forward quoting' do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('forward-quoting-example.email', ir.incoming_email)
    message = ir.incoming_messages[1]
    expect(message.get_main_body_text_folded).to match(/FOLDED_QUOTED_SECTION/)
  end

  it 'should fold a further example of forward quoting' do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('forward-quoting-example-2.email', ir.incoming_email)
    message = ir.incoming_messages[1]
    body_text = message.get_main_body_text_folded
    expect(body_text).to match(/FOLDED_QUOTED_SECTION/)
    # check that the quoted section incorporates both quoted messages
    expect(body_text).not_to match('Subject: RE: Freedom of Information request')
  end

end

describe IncomingMessage, " checking validity to reply to" do
  def test_email(result, email, empty_return_path, autosubmitted = nil)
    @mail = double('mail')
    allow(MailHandler).to receive(:get_from_address).and_return(email)
    allow(MailHandler).to receive(:empty_return_path?).with(@mail).and_return(empty_return_path)
    allow(MailHandler).to receive(:get_auto_submitted).with(@mail).and_return(autosubmitted)
    @incoming_message = IncomingMessage.new
    allow(@incoming_message).to receive(:mail).and_return(@mail)
    expect(@incoming_message._calculate_valid_to_reply_to).to eq(result)
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
    expect(ir.incoming_messages[1].valid_to_reply_to?).to eq(true)
  end
  it "should not allow a reply to emails with empty return-paths" do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('empty-return-path.email', ir.incoming_email)
    expect(ir.incoming_messages[1].valid_to_reply_to?).to eq(false)
  end
  it "should not allow a reply to emails with autoresponse headers" do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('autoresponse-header.email', ir.incoming_email)
    expect(ir.incoming_messages[1].valid_to_reply_to?).to eq(false)
  end

end


describe IncomingMessage, " when censoring data" do

  before(:each) do
    @test_data = "There was a mouse called Stilton, he wished that he was blue."

    @im = incoming_messages(:useless_incoming_message)

    @censor_rule_1 = CensorRule.new
    @censor_rule_1.text = "Stilton"
    @censor_rule_1.replacement = "Jarlsberg"
    @censor_rule_1.last_edit_editor = "unknown"
    @censor_rule_1.last_edit_comment = "none"
    @im.info_request.censor_rules << @censor_rule_1

    @censor_rule_2 = CensorRule.new
    @censor_rule_2.text = "blue"
    @censor_rule_2.replacement = "yellow"
    @censor_rule_2.last_edit_editor = "unknown"
    @censor_rule_2.last_edit_comment = "none"
    @im.info_request.censor_rules << @censor_rule_2

    @regex_censor_rule = CensorRule.new
    @regex_censor_rule.text = 'm[a-z][a-z][a-z]e'
    @regex_censor_rule.regexp = true
    @regex_censor_rule.replacement = 'cat'
    @regex_censor_rule.last_edit_editor = 'unknown'
    @regex_censor_rule.last_edit_comment = 'none'
    @im.info_request.censor_rules << @regex_censor_rule
    load_raw_emails_data
  end

  it "should replace censor text" do
    data = "There was a mouse called Stilton, he wished that he was blue."
    @im.apply_masks!(data, "application/vnd.ms-word")
    expect(data).to eq("There was a xxxxx called xxxxxxx, he wished that he was xxxx.")
  end

  it "should apply censor rules to From: addresses" do
    allow(@im).to receive(:mail_from).and_return("Stilton Mouse")
    allow(@im).to receive(:last_parsed).and_return(Time.now)
    safe_mail_from = @im.safe_mail_from
    expect(safe_mail_from).to eq("Jarlsberg Mouse")
  end

end

describe IncomingMessage, " when censoring whole users" do

  before(:each) do
    @test_data = "There was a mouse called Stilton, he wished that he was blue."

    @im = incoming_messages(:useless_incoming_message)

    @censor_rule_1 = CensorRule.new
    @censor_rule_1.text = "Stilton"
    @censor_rule_1.replacement = "Gorgonzola"
    @censor_rule_1.last_edit_editor = "unknown"
    @censor_rule_1.last_edit_comment = "none"
    @im.info_request.user.censor_rules << @censor_rule_1
    load_raw_emails_data
  end

  it "should apply censor rules to HTML files" do
    data = @test_data.dup
    @im.apply_masks!(data, 'text/html')
    expect(data).to eq("There was a mouse called Gorgonzola, he wished that he was blue.")
  end

  it "should replace censor text to Word documents" do
    data = @test_data.dup
    @im.apply_masks!(data, "application/vnd.ms-word")
    expect(data).to eq("There was a mouse called xxxxxxx, he wished that he was blue.")
  end

end


describe IncomingMessage, " when uudecoding bad messages" do

  it "decodes a valid uuencoded attachment" do
    mail = get_fixture_mail('simple-uuencoded-attachment.email')
    im = incoming_messages(:useless_incoming_message)
    allow(im).to receive(:mail).and_return(mail)
    im.extract_attachments!

    im.reload
    attachments = im.foi_attachments
    expect(attachments.size).to eq(2)
    expect(attachments[1].filename).to eq('Happy.txt')
    expect(attachments[1].body).to eq("Happy today for to be one of peace and serene time.\n")
    expect(im.get_attachments_for_display.size).to eq(1)
  end

  it "should be able to do it at all" do
    mail = get_fixture_mail('incoming-request-bad-uuencoding.email')
    im = incoming_messages(:useless_incoming_message)
    allow(im).to receive(:mail).and_return(mail)
    im.extract_attachments!

    im.reload
    attachments = im.foi_attachments
    expect(attachments.size).to eq(2)
    expect(attachments[1].filename).to eq('moo.txt')
    expect(im.get_attachments_for_display.size).to eq(1)
  end

  it "decodes an attachment where the uudecode program reports a 'No end line' error" do
    # See https://github.com/mysociety/alaveteli/issues/2508
    mail = get_fixture_mail('incoming-request-bad-uuencoding-2.email')
    im = incoming_messages(:useless_incoming_message)
    allow(im).to receive(:mail).and_return(mail)
    im.extract_attachments!

    im.reload
    attachments = im.foi_attachments
    expect(attachments.size).to eq(2)
    expect(attachments[1].filename).to eq('ResponseT5741 15.doc')
    expect(attachments[1].display_size).to eq('123K')
    expect(im.get_attachments_for_display.size).to eq(1)
  end

  it "should still work when parsed from the raw email" do
    raw_email = load_file_fixture 'inline-uuencode.email'
    mail = MailHandler.mail_from_raw_email(raw_email)
    im = incoming_messages :useless_incoming_message
    allow(im).to receive(:raw_email).and_return(raw_email)
    allow(im).to receive(:mail).and_return(mail)
    im.parse_raw_email!
    attachments = im.foi_attachments
    expect(attachments.size).to eq(2)
  end

  it "should apply censor rules" do
    mail = get_fixture_mail('incoming-request-bad-uuencoding.email')

    im = incoming_messages(:useless_incoming_message)
    allow(im).to receive(:mail).and_return(mail)
    ir = info_requests(:fancy_dog_request)

    @censor_rule = CensorRule.new
    @censor_rule.text = "moo"
    @censor_rule.replacement = "bah"
    @censor_rule.last_edit_editor = "unknown"
    @censor_rule.last_edit_comment = "none"
    ir.censor_rules << @censor_rule
    im.extract_attachments!

    expect(im.get_attachments_for_display.map(&:display_filename)).to eq([
      'bah.txt',
    ])
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
      allow(im).to receive(:mail).and_return(mail)

      attachments = im.get_attachments_for_display
      expect(attachments.size).to eq(1)
      attachment = attachments.first

      expect(attachment.content_type).to eq('text/plain')
      expect(attachment.filename).to eq("Freedom of Information request.txt")
      expect(attachment.charset).to eq("utf-8")
      expect(attachment.within_rfc822_subject).to eq("Freedom of Information request")
      expect(attachment.hexdigest).to eq('f10fe56e4f2287685a58b71329f09639')
    end
  end

  it "should flatten all the attachments out" do
    mail = get_fixture_mail('incoming-request-attach-attachments.email')

    im = incoming_messages(:useless_incoming_message)
    allow(im).to receive(:mail).and_return(mail)

    im.extract_attachments!

    attachments = im.get_attachments_for_display
    expect(attachments.map(&:display_filename)).to eq([
      'Same attachment twice.txt',
      'hello.txt',
      'hello.txt',
    ])
  end

  it 'should add headers to attached plain text message bodies' do
    # Note that this spec will only pass using Tmail in the timezone set as datetime headers
    # are rendered out in the local time - using the Mail gem this is not necessary
    with_env_tz('London') do
      mail_body = load_file_fixture('incoming-request-attachment-headers.email')
      mail = MailHandler.mail_from_raw_email(mail_body)

      im = incoming_messages(:useless_incoming_message)
      allow(im).to receive(:mail).and_return(mail)

      attachments = im.get_attachments_for_display
      expect(attachments.size).to eq(2)
      expect(attachments[0].body).to match('Date: Fri, 23 May 2008')
    end
  end

end

describe IncomingMessage, "when Outlook messages are attached to messages" do

  it "should flatten all the attachments out" do
    mail = get_fixture_mail('incoming-request-oft-attachments.email')

    im = incoming_messages(:useless_incoming_message)
    allow(im).to receive(:mail).and_return(mail)
    im.extract_attachments!

    expect(im.get_attachments_for_display.map(&:display_filename)).to eq([
      'test.html',  # picks HTML rather than text by default, as likely to render better
      'attach.txt',
    ])
  end
end

describe IncomingMessage, "when TNEF attachments are attached to messages" do

  it "should flatten all the attachments out" do
    mail = get_fixture_mail('incoming-request-tnef-attachments.email')

    im = incoming_messages(:useless_incoming_message)
    allow(im).to receive(:mail).and_return(mail)
    im.extract_attachments!

    expect(im.get_attachments_for_display.map(&:display_filename)).to eq([
      'FOI 09 02976i.doc',
      'FOI 09 02976iii.doc',
    ])
  end
end

describe IncomingMessage, "when extracting attachments" do

  before do
    load_raw_emails_data
  end

  it 'handles the case where reparsing changes the body of the main part
        and the cached attachment has been deleted' do
    # original set of attachment attributes
    attachment_attributes = { :url_part_number => 1,
                              :within_rfc822_subject => nil,
                              :content_type => "text/plain",
                              :charset => nil,
                              :body => "No way!\n",
                              :hexdigest => "0c8b1b0f5cb9c94ed15a180e73b5c7d1",
                              :filename => nil }

    # Make a small change in the body returned for the attachment
    new_attachment_attributes = attachment_attributes.merge(:body => "No way!",
                                                            :hexdigest => "74d2c0a41e074f9cebe49324d5b47414")


    # Simulate parsing with the original attachments
    allow(MailHandler).to receive(:get_attachment_attributes).and_return([attachment_attributes])
    incoming_message = incoming_messages(:useless_incoming_message)

    # Extract the attachments
    incoming_message.extract_attachments!

    # delete the cached file for the main body part
    main = incoming_message.get_main_body_text_part
    main.delete_cached_file!

    # Simulate reparsing with the slightly changed body
    allow(MailHandler).to receive(:get_attachment_attributes).and_return([new_attachment_attributes])

    # Re-extract the attachments
    incoming_message.extract_attachments!

    attachments = incoming_message.foi_attachments
    expect(attachments.size).to eq(1)
    expect(attachments.first.hexdigest).to eq("74d2c0a41e074f9cebe49324d5b47414")
    expect(attachments.first.body).to eq('No way!')
  end

  it 'makes invalid utf-8 encoded attachment text valid when string responds to encode' do
    if String.method_defined?(:encode)
      im = incoming_messages(:useless_incoming_message)
      allow(im).to receive(:extract_text).and_return("\xBF")

      expect(im._get_attachment_text_internal.valid_encoding?).to be true
    end
  end

end

describe IncomingMessage do

  describe '#_extract_text' do

    it 'does not generate incompatible character encodings' do
      if String.respond_to?(:encode)
        message = FactoryGirl.create(:incoming_message)
        FactoryGirl.create(:body_text,
                           :body => 'hí',
                           :incoming_message => message,
                           :url_part_number => 2)
        FactoryGirl.create(:pdf_attachment,
                           :body => load_file_fixture('pdf-with-utf8-characters.pdf'),
                           :incoming_message => message,
                           :url_part_number => 3)
        message.reload

        expect{ message._extract_text }.
          to_not raise_error
      end
    end

  end

end

describe IncomingMessage, 'when getting the body of a message for html display' do

  it 'should replace any masked email addresses with a link to the help page' do
    incoming_message = IncomingMessage.new
    body_text = 'there was an [email address] here'
    allow(incoming_message).to receive(:get_main_body_text_folded).and_return(body_text)
    allow(incoming_message).to receive(:get_main_body_text_unfolded).and_return(body_text)
    expected = 'there was an [<a href="/help/officers#mobiles">email address</a>] here'
    expect(incoming_message.get_body_for_html_display).to eq(expected)
  end

end

describe IncomingMessage, 'when getting clipped attachment text' do

  it 'should clip to characters not bytes' do
    incoming_message = FactoryGirl.build(:incoming_message)
    # This character is 2 bytes so the string should get sliced unless
    # we are handling multibyte chars correctly
    multibyte_string = "å" * 500002
    allow(incoming_message).to receive(:_get_attachment_text_internal).and_return(multibyte_string)
    expect(incoming_message.get_attachment_text_clipped.length).to eq(500002)
  end
end
