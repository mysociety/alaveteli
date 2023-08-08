# == Schema Information
# Schema version: 20220210120801
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
#  from_email_domain              :text
#  valid_to_reply_to              :boolean
#  last_parsed                    :datetime
#  from_name                      :text
#  sent_at                        :datetime
#  prominence                     :string           default("normal"), not null
#  prominence_reason              :text
#  from_email                     :text
#

require 'spec_helper'
require 'models/concerns/message_prominence'
require 'models/concerns/taggable'

RSpec.describe IncomingMessage do
  it_behaves_like 'concerns/message_prominence', :incoming_message
  it_behaves_like 'concerns/taggable', :incoming_message

  describe '.unparsed' do
    subject { described_class.unparsed }
    before { IncomingMessage.destroy_all }

    it 'does not include parsed messages' do
      FactoryBot.create(:incoming_message)
      unparsed = FactoryBot.create(:incoming_message, :unparsed)
      expect(subject).to match_array [unparsed]
    end
  end

  describe '.pro' do
    subject { described_class.pro }
    before { IncomingMessage.destroy_all }

    it 'finds messages belonging to pro users' do
      FactoryBot.create(:incoming_message)
      pro_user = FactoryBot.create(:pro_user)
      embargoed_request = FactoryBot.create(:embargoed_request, user: pro_user)
      pro_message = embargoed_request.incoming_messages.first
      expect(subject).to match_array [pro_message]
    end
  end

  describe '#response_event' do
    subject { message.response_event }

    let(:message) { FactoryBot.build(:incoming_message) }

    %i[comment_event response_event].each do |event_type|
      let!(event_type) do
        FactoryBot.create(event_type, incoming_message: message)
      end
    end

    it { is_expected.to eq(response_event) }
  end

  describe '#from_name' do

    it 'returns the name in the From: field of an email' do
      raw_email_data = <<-EOF.strip_heredoc
      From: FOI Person <authority@example.com>
      To: Jane Doe <request-magic-email@example.net>
      Subject: A response
      Hello, World
      EOF

      message = FactoryBot.create(:incoming_message)
      message.raw_email.data = raw_email_data
      message.parse_raw_email!(true)
      expect(message.from_name).to eq('FOI Person')
    end

    it 'returns nil if there is no name in the From: field of an email' do
      raw_email_data = <<-EOF.strip_heredoc
      From: authority@example.com
      To: Jane Doe <request-magic-email@example.net>
      Subject: A response
      Hello, World
      EOF

      message = FactoryBot.create(:incoming_message)
      message.raw_email.data = raw_email_data
      message.parse_raw_email!(true)
      expect(message.from_name).to be_nil
    end

    it 'unquotes RFC 2047 headers' do
      raw_email_data = <<-EOF.strip_heredoc
      From: =?iso-8859-1?Q?Coordena=E7=E3o_de_Relacionamento=2C_Pesquisa_e_Informa=E7?=
      	=?iso-8859-1?Q?=E3o/CEDI?= <geraldinequango@localhost>
      To: Jane Doe <request-magic-email@example.net>
      Subject: A response
      Hello, World
      EOF

      message = FactoryBot.create(:incoming_message)
      message.raw_email.data = raw_email_data
      message.parse_raw_email!(true)
      expect(message.from_name).
        to eq('Coordenação de Relacionamento, Pesquisa e Informação/CEDI')
    end

  end

  describe '#safe_from_name' do

    it 'applies the info request censor rules to from_name' do
      raw_email_data = <<-EOF.strip_heredoc
      From: FOI Person <authority@example.com>
      To: Jane Doe <request-magic-email@example.net>
      Subject: A response
      Hello, World
      EOF

      message = FactoryBot.create(:incoming_message)
      message.raw_email.data = raw_email_data
      message.parse_raw_email!(true)
      message.reload
      FactoryBot.create(:censor_rule,
                        text: 'Person',
                        info_request: message.info_request)

      expect(message.safe_from_name).to eq('FOI [REDACTED]')
    end

  end

  describe '#from_email' do

    it 'returns the email address in the From header' do
      raw_email_data = <<-EOF.strip_heredoc
      From: FOI Person <authority@mail.example.com>
      To: Jane Doe <request-magic-email@example.net>
      Subject: A response
      Hello, World
      EOF

      message = FactoryBot.create(:incoming_message)
      message.raw_email.data = raw_email_data
      message.parse_raw_email!(true)
      expect(message.from_email).to eq('authority@mail.example.com')
    end

    it 'returns an empty string if there is no From header' do
      raw_email_data = <<-EOF.strip_heredoc
      To: Jane Doe <request-magic-email@example.net>
      Subject: A response
      Hello, World
      EOF

      message = FactoryBot.create(:incoming_message)
      message.raw_email.data = raw_email_data
      message.parse_raw_email!(true)
      expect(message.from_email).to eq('')
    end

  end

  describe '#from_email_domain' do

    it 'returns the domain part of the email address in the From header' do
      raw_email_data = <<-EOF.strip_heredoc
      From: FOI Person <authority@mail.example.com>
      To: Jane Doe <request-magic-email@example.net>
      Subject: A response
      Hello, World
      EOF

      message = FactoryBot.create(:incoming_message)
      message.raw_email.data = raw_email_data
      message.parse_raw_email!(true)
      expect(message.from_email_domain).to eq('mail.example.com')
    end

    it 'returns an empty string if there is no From header' do
      raw_email_data = <<-EOF.strip_heredoc
      To: Jane Doe <request-magic-email@example.net>
      Subject: A response
      Hello, World
      EOF

      message = FactoryBot.create(:incoming_message)
      message.raw_email.data = raw_email_data
      message.parse_raw_email!(true)
      expect(message.from_email_domain).to eq('')
    end

  end

  describe '#subject' do

    it 'returns the Subject: field of an email' do
      raw_email_data = <<-EOF.strip_heredoc
      From: FOI Person <authority@example.com>
      To: Jane Doe <request-magic-email@example.net>
      Subject: A response
      Hello, World
      EOF

      message = FactoryBot.create(:incoming_message)
      message.raw_email.data = raw_email_data
      message.parse_raw_email!(true)
      expect(message.subject).to eq('A response')
    end

    it 'returns nil if there is no Subject: field' do
      raw_email_data = <<-EOF.strip_heredoc
      From: FOI Person <authority@example.com>
      To: Jane Doe <request-magic-email@example.net>
      Hello, World
      EOF

      message = FactoryBot.create(:incoming_message)
      message.raw_email.data = raw_email_data
      message.parse_raw_email!(true)
      expect(message.subject).to be_nil
    end

    it 'unquotes RFC 2047 headers' do
      raw_email_data = <<-EOF.strip_heredoc
      From: FOI Person <authority@example.com>
      To: Jane Doe <request-magic-email@example.net>
      Subject: =?iso-8859-1?Q?C=E2mara_Responde=3A__Banco_de_ideias?=
      Hello, World
      EOF

      message = FactoryBot.create(:incoming_message)
      message.raw_email.data = raw_email_data
      message.parse_raw_email!(true)
      expect(message.subject).to eq('Câmara Responde:  Banco de ideias')
    end

  end

  describe '#sent_at' do

    it 'uses the Date header if the mail has one' do
      raw_email_data = <<-EOF.strip_heredoc
      From: FOI Person <authority@example.com>
      To: Jane Doe <request-magic-email@example.net>
      Subject: A response
      Date: Fri, 9 Dec 2011 10:42:02 -0200
      Hello, World
      EOF

      message = FactoryBot.create(:incoming_message)
      message.raw_email.data = raw_email_data
      message.parse_raw_email!(true)
      expect(message.sent_at).
        to eq(DateTime.parse('Fri, 9 Dec 2011 10:42:02 -0200').in_time_zone)
    end

    it 'uses the created_at attribute if there is no Date header' do
      raw_email_data = <<-EOF.strip_heredoc
      From: FOI Person <authority@example.com>
      To: Jane Doe <request-magic-email@example.net>
      Subject: A response
      Hello, World
      EOF

      message = FactoryBot.create(:incoming_message)
      message.raw_email.data = raw_email_data
      message.parse_raw_email!(true)
      expect(message.sent_at).to eq(message.created_at)
    end

  end

  describe '#specific_from_name?' do
    subject { incoming_message.specific_from_name? }

    let(:body) { FactoryBot.build(:public_body, name: 'Foo') }
    let(:request) { FactoryBot.build(:info_request, public_body: body) }

    context 'when from_name is nil' do
      let(:incoming_message) do
        FactoryBot.build(:incoming_message, from_name: nil)
      end

      it { is_expected.to eq(false) }
    end

    context 'when safe_from_name is the same as the body name' do
      let(:incoming_message) do
        FactoryBot.
          build(:incoming_message, info_request: request, from_name: 'Foo')
      end

      it { is_expected.to eq(false) }
    end

    context 'when safe_from_name differs from the body name' do
      let(:incoming_message) do
        FactoryBot.
          build(:incoming_message, info_request: request, from_name: 'Bar')
      end

      it { is_expected.to eq(true) }
    end

    context 'a censor rule masks from_name' do
      let(:incoming_message) do
        FactoryBot.create(:global_censor_rule, text: 'Bar')
        FactoryBot.build(:incoming_message, from_name: 'Bar')
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '#apply_masks' do

    before(:each) do
      @im = incoming_messages(:useless_incoming_message)

      @default_opts = { last_edit_editor: 'unknown',
                        last_edit_comment: 'none' }

      load_raw_emails_data
    end

    it 'replaces text with global censor rules' do
      data = 'There was a mouse called Stilton, he wished that he was blue'
      expected = 'There was a mouse called Stilton, he said that he was blue'

      opts = { text: 'wished',
               replacement: 'said' }.merge(@default_opts)
      CensorRule.create!(opts)

      result = @im.apply_masks(data, 'text/plain')

      expect(result).to eq(expected)
    end

    it 'replaces text with censor rules belonging to the info request' do
      data = 'There was a mouse called Stilton.'
      expected = 'There was a cat called Jarlsberg.'

      rules = [
        { text: 'Stilton', replacement: 'Jarlsberg' },
        { text: 'm[a-z][a-z][a-z]e', regexp: true, replacement: 'cat' }
      ]

      rules.each do |rule|
        @im.info_request.censor_rules << CensorRule.new(rule.merge(@default_opts))
      end

      result = @im.apply_masks(data, 'text/plain')
      expect(result).to eq(expected)
    end

    it 'replaces text with censor rules belonging to the user' do
      data = 'There was a mouse called Stilton.'
      expected = 'There was a cat called Jarlsberg.'

      rules = [
        { text: 'Stilton', replacement: 'Jarlsberg' },
        { text: 'm[a-z][a-z][a-z]e', regexp: true, replacement: 'cat' }
      ]

      rules.each do |rule|
        @im.info_request.user.censor_rules << CensorRule.new(rule.merge(@default_opts))
      end

      result = @im.apply_masks(data, 'text/plain')
      expect(result).to eq(expected)
    end

    it 'replaces text with masks belonging to the info request' do
      data = "He emailed #{ @im.info_request.incoming_email }"
      expected = "He emailed [FOI ##{ @im.info_request.id } email]"
      result = @im.apply_masks(data, 'text/plain')
      expect(result).to eq(expected)
    end

    it 'replaces text with global masks' do
      data = 'His email address was stilton@example.org'
      expected = 'His email address was [email address]'
      result = @im.apply_masks(data, 'text/plain')
      expect(result).to eq(expected)
    end

    it 'replaces text in binary files' do
      data = 'His email address was stilton@example.org'
      expected = 'His email address was xxxxxxx@xxxxxxx.xxx'
      result = @im.apply_masks(data, 'application/vnd.ms-word')
      expect(result).to eq(expected)
    end

  end

  describe '#get_body_for_indexing' do
    subject { incoming_message.get_body_for_indexing }

    let(:incoming_message) { FactoryBot.build(:incoming_message) }

    context 'guest can read main body part' do
      it 'returns body for text display' do
        is_expected.to eq('hereisthetext')
      end
    end

    context 'guest cannot read main body part' do
      before do
        ability = Object.new.extend(CanCan::Ability)
        ability.cannot :read, incoming_message.get_main_body_text_part
        allow(Ability).to receive(:guest).and_return(ability)
      end

      it 'returns blank string' do
        is_expected.to eq ''
      end
    end
  end

  describe '#get_body_for_quoting' do

    it 'does not incorrectly cache without the FOLDED_QUOTED_SECTION marker' do
      message = FactoryBot.create(:plain_incoming_message)
      message.get_body_for_quoting
      expect(message.get_main_body_text_folded).
        to include('FOLDED_QUOTED_SECTION')
    end

  end

  describe '#get_attachment_text_full' do

    it 'strips null bytes from the extracted clipped text' do
      message = FactoryBot.create(:incoming_message)
      FactoryBot.
        create(:body_text, body: "hi\u0000", incoming_message: message)
      message.reload
      expect(message.get_attachment_text_clipped).to eq("hi\n\n")
    end

  end

  describe '#_extract_text' do

    it 'does not generate incompatible character encodings' do
      message = FactoryBot.create(:incoming_message)
      FactoryBot.create(:body_text,
                        body: 'hí',
                        incoming_message: message,
                        url_part_number: 2)
      FactoryBot.create(:pdf_attachment,
                        body: load_file_fixture('pdf-with-utf8-characters.pdf'),
                        incoming_message: message,
                        url_part_number: 3)
      message.reload

      expect { message._extract_text }.
        to_not raise_error
    end

  end

  describe '#legislation' do
    let(:info_request) { FactoryBot.build(:info_request) }

    let(:message) do
      FactoryBot.build(:incoming_message, info_request: info_request)
    end

    it 'delegates to the info request' do
      legislation = double(:legislation)
      expect(info_request).to receive(:legislation).and_return(legislation)
      expect(message.legislation).to eq legislation
    end
  end

  describe '#refusals' do
    let(:message) { FactoryBot.build(:incoming_message) }
    let(:legislation) { double(:legislation) }

    before do
      allow(message).to receive(:get_main_body_text_folded).and_return('TEXT')
      allow(message).to receive(:legislation).and_return(legislation)
    end

    it 'finds references' do
      expect(legislation).to receive(:find_references).with('TEXT').
        and_return([])
      message.refusals
    end

    it 'returns references which are refusals' do
      refusal_1 = double(:refusal_1, refusal?: true).as_null_object
      refusal_2 = double(:refusal_2, refusal?: true).as_null_object
      other = double(:not_refusal, refusal?: false)

      allow(legislation).to receive(:find_references).and_return(
        [refusal_1, refusal_2, other]
      )
      expect(message.refusals).to match_array([refusal_1, refusal_2])
    end

    it 'returns unique parent references based on the parent to_s' do
      parent_1 = double(:parent_1, to_s: 'Section 1')
      parent_2 = double(:parent_2, to_s: 'Section 1')
      refusal_1 = double(:refusal_1, refusal?: true, parent: parent_1)
      refusal_2 = double(:refusal_2, refusal?: true, parent: parent_2)

      allow(legislation).to receive(:find_references).and_return(
        [refusal_1, refusal_2]
      )
      expect(message.refusals).to match_array([parent_1])
    end
  end

  describe '#refusals?' do
    subject { message.refusals? }

    let(:message) { FactoryBot.build(:incoming_message) }

    context 'if there are refusals' do
      before { allow(message).to receive(:refusals).and_return([double]) }
      it { is_expected.to eq(true) }
    end

    context 'if there are no refusals' do
      before { allow(message).to receive(:refusals).and_return([]) }
      it { is_expected.to eq(false) }
    end
  end
end

RSpec.describe IncomingMessage, "when the prominence is changed" do
  let(:request) { FactoryBot.create(:info_request) }

  it "updates the info_request's last_public_response_at to nil when hidden" do
    im = FactoryBot.create(:incoming_message, info_request: request)
    response_event = FactoryBot.
                      create(:info_request_event, event_type: 'response',
                                                  info_request: request,
                                                  incoming_message: im)
    im.prominence = 'hidden'
    im.save!
    expect(request.last_public_response_at).to be_nil
  end

  it "updates the info_request's last_public_response_at to a timestamp \
      when unhidden" do
    im = FactoryBot.create(:incoming_message, prominence: 'hidden',
                                              info_request: request)
    response_event = FactoryBot.
                       create(:info_request_event, event_type: 'response',
                                                   info_request: request,
                                                   incoming_message: im)
    im.prominence = 'normal'
    im.save!
    expect(request.last_public_response_at).to be_within(1.second).
      of(response_event.created_at)
  end

end

RSpec.describe 'when destroying a message' do
  let(:incoming_message) { FactoryBot.create(:plain_incoming_message) }

  it 'destroys the incoming message' do
    incoming_message.destroy
    expect(IncomingMessage.where(id: incoming_message.id)).to be_empty
  end

  it 'should destroy the related info_request_event' do
    info_request = incoming_message.info_request
    info_request.log_event(
      'response',
      incoming_message_id: incoming_message.id
    )
    incoming_message.reload
    incoming_message.destroy
    expect(InfoRequestEvent.where(incoming_message_id: incoming_message.id)).
      to be_empty
  end

  it 'should nullify outgoing_message_followups' do
    outgoing_message = FactoryBot.
                         create(:initial_request,
                                info_request: incoming_message.info_request,
                                incoming_message_followup_id: incoming_message.id)
    incoming_message.reload
    incoming_message.destroy

    expect(OutgoingMessage.
      where(incoming_message_followup_id: incoming_message.id)).to be_empty
    expect(OutgoingMessage.where(id: outgoing_message.id)).
      to eq([outgoing_message])
  end

  it 'destroys the associated raw email' do
    raw_email = incoming_message.raw_email
    incoming_message.destroy
    expect(RawEmail.where(id: raw_email.id)).to be_empty
  end

  context 'with attachments' do
    let(:incoming_with_attachment) {
      FactoryBot.create(:incoming_message_with_html_attachment)
    }

    it 'destroys the incoming message' do
      incoming_with_attachment.destroy
      expect(IncomingMessage.where(id: incoming_with_attachment.id)).
        to be_empty
    end

    it 'should destroy associated attachments' do
      incoming_with_attachment.destroy
      expect(
        FoiAttachment.where(incoming_message_id: incoming_with_attachment.id)
      ).to be_empty
    end
  end
end

RSpec.describe IncomingMessage, " when dealing with incoming mail" do

  before(:each) do
    @im = incoming_messages(:useless_incoming_message)
    load_raw_emails_data
  end

  after(:all) do
    ActionMailer::Base.deliveries.clear
  end

  it 'should correctly parse multipart mails with a linebreak in the boundary marker' do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('space-boundary.email', email_to: ir.incoming_email)
    message = ir.incoming_messages[1]
    expect(message.parts.size).to eq(2)
    expect(message.multipart?).to eq(true)
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
    receive_incoming_mail('quoted-subject-iso8859-1.email',
                          email_to: ir.incoming_email)
    message = ir.incoming_messages[1]
    expect(message.get_main_body_text_unfolded).not_to include("Email has no body")
  end

  it "should correctly convert HTML even when there's a meta tag asserting that it is iso-8859-1 which would normally confuse elinks" do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('quoted-subject-iso8859-1.email',
                          email_to: ir.incoming_email)
    message = ir.incoming_messages[1]
    message.parse_raw_email!
    expect(message.get_main_body_text_part.charset).to eq("iso-8859-1")
    expect(message.get_main_body_text_internal).to include("política")
  end

  it 'should deal with GB18030 text even if the charset is missing' do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('no-part-charset-bad-utf8.email',
                          email_to: ir.incoming_email)
    message = ir.incoming_messages[1]
    message.parse_raw_email!
    expect(message.get_main_body_text_internal).to include("贵公司负责人")
  end

  it 'should not error on display of a message which has no charset set on the body part and is not good UTF-8' do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('no-part-charset-random-data.email',
                          email_to: ir.incoming_email)
    message = ir.incoming_messages[1]
    message.parse_raw_email!
    expect(message.get_main_body_text_internal).to include("The above text was badly encoded")
  end

  it 'should convert DOS-style linebreaks to Unix style' do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('dos-linebreaks.email', email_to: ir.incoming_email)
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
      "foo\n--------\nbar\n- - - - - - - -\nconfidential\n--------\nrest" => "foo\n--------\nbar\nFOLDED_QUOTED_SECTION\nrest" # allow spaces in the score
    }.each do |input,output|
      expect(IncomingMessage.remove_quoted_sections(input)).to eq(output)
    end
  end

  it 'should insert some text for messages without a body' do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('no-body.email', email_to: ir.incoming_email)
    message = ir.incoming_messages[1]
    message.parse_raw_email!
    expect(message.get_main_body_text_internal).
      to eq "[ Email has no body, please see attachments ]"
  end

  it "should load an email with funny MIME settings" do
    ActionMailer::Base.deliveries.clear
    # just send it to the holding pen
    expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(0)
    receive_incoming_mail("humberside-police-odd-mime-type.email",
                          email_to: 'dummy')
    expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(1)

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

RSpec.describe IncomingMessage, " display attachments" do

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

RSpec.describe IncomingMessage, " folding quoted parts of emails" do

  it 'should fold an example lotus notes quoted part converted from HTML correctly' do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('lotus-notes-quoting.email',
                          email_to: ir.incoming_email)
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
    receive_incoming_mail('forward-quoting-example.email',
                          email_to: ir.incoming_email)
    message = ir.incoming_messages[1]
    expect(message.get_main_body_text_folded).to match(/FOLDED_QUOTED_SECTION/)
  end

  it 'should fold a further example of forward quoting' do
    ir = info_requests(:fancy_dog_request)
    receive_incoming_mail('forward-quoting-example-2.email',
                          email_to: ir.incoming_email)
    message = ir.incoming_messages[1]
    body_text = message.get_main_body_text_folded
    expect(body_text).to match(/FOLDED_QUOTED_SECTION/)
    # check that the quoted section incorporates both quoted messages
    expect(body_text).not_to match('Subject: RE: Freedom of Information request')
  end

end

RSpec.describe IncomingMessage, " when uudecoding bad messages" do
  let(:raw_email) { FactoryBot.create(:raw_email) }

  let(:im) do
    FactoryBot.create(:incoming_message, raw_email: raw_email)
  end

  let(:to) { im.info_request.incoming_email }
  let(:from) { im.info_request.public_body.request_email }

  def populate_raw_email(fixture)
    mail = get_fixture_mail(fixture, to, from)
    raw_email.update!(data: mail)
  end

  it "decodes a valid uuencoded attachment" do
    populate_raw_email('simple-uuencoded-attachment.email')
    im.extract_attachments!

    im.reload
    attachments = im.foi_attachments
    expect(attachments.size).to eq(2)
    allow(attachments[1]).to receive(:masked?).and_return(true)
    expect(attachments[1].filename).to eq('Happy.txt')
    expect(attachments[1].body).to eq("Happy today for to be one of peace and serene time.\n")
    expect(im.get_attachments_for_display.size).to eq(1)
  end

  it "should be able to do it at all" do
    populate_raw_email('incoming-request-bad-uuencoding.email')
    im.extract_attachments!

    im.reload
    attachments = im.foi_attachments
    expect(attachments.size).to eq(2)
    expect(attachments[1].filename).to eq('moo.txt')
    expect(im.get_attachments_for_display.size).to eq(1)
  end

  it "decodes an attachment where the uudecode program reports a 'No end line' error" do
    # See https://github.com/mysociety/alaveteli/issues/2508
    populate_raw_email('incoming-request-bad-uuencoding-2.email')
    im.extract_attachments!

    im.reload
    attachments = im.foi_attachments
    expect(attachments.size).to eq(2)
    expect(attachments[1].filename).to eq('ResponseT5741 15.doc')
    expect(attachments[1].display_size).to eq('123K')
    expect(im.get_attachments_for_display.size).to eq(1)
  end

  it "should still work when parsed from the raw email" do
    data = load_file_fixture('inline-uuencode.email')
    mail = MailHandler.mail_from_raw_email(data)
    im = incoming_messages(:useless_incoming_message)
    raw_email = RawEmail.new
    allow(raw_email).to receive(:data).and_return(data)
    allow(im).to receive(:raw_email).and_return(raw_email)
    allow(im).to receive(:mail).and_return(mail)
    im.parse_raw_email!(true)
    attachments = im.foi_attachments
    expect(attachments.size).to eq(2)
  end

  it "should apply censor rules" do
    populate_raw_email('incoming-request-bad-uuencoding.email')
    ir = im.info_request

    @censor_rule = CensorRule.new
    @censor_rule.text = "moo"
    @censor_rule.replacement = "bah"
    @censor_rule.last_edit_editor = "unknown"
    @censor_rule.last_edit_comment = "none"
    ir.censor_rules << @censor_rule
    im.extract_attachments!

    expect(im.get_attachments_for_display.map(&:display_filename)).to eq([
      'bah.txt'
    ])
  end

end

RSpec.describe IncomingMessage, "when messages are attached to messages" do
  let(:raw_email) { FactoryBot.create(:raw_email) }

  let(:im) do
    FactoryBot.create(:incoming_message, raw_email: raw_email)
  end

  let(:to) { im.info_request.incoming_email }
  let(:from) { im.info_request.public_body.request_email }

  def populate_raw_email(fixture)
    mail = get_fixture_mail(fixture, to, from)
    raw_email.update!(data: mail)
  end

  it 'should expand an RFC822 attachment' do
    # Note that this spec will only pass using Tmail in the timezone set as datetime headers
    # are rendered out in the local time - using the Mail gem this is not necessary
    with_env_tz('London') do
      populate_raw_email('rfc822-attachment.email')
      im.parse_raw_email!(true)
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
    populate_raw_email('incoming-request-attach-attachments.email')
    im.extract_attachments!

    attachments = im.get_attachments_for_display
    expect(attachments.map(&:display_filename)).to eq([
      'Same attachment twice.txt',
      'hello.txt',
      'hello.txt'
    ])
  end

  it 'should add headers to attached plain text message bodies' do
    # Note that this spec will only pass using Tmail in the timezone set as datetime headers
    # are rendered out in the local time - using the Mail gem this is not necessary
    with_env_tz('London') do
      populate_raw_email('incoming-request-attachment-headers.email')
      im.parse_raw_email!(true)
      attachments = im.get_attachments_for_display
      expect(attachments.size).to eq(2)
      expect(attachments[0].body).to match('Date: Fri, 23 May 2008')
    end
  end

end

RSpec.describe IncomingMessage, "when Outlook messages are attached to messages" do
  let(:raw_email) { FactoryBot.create(:raw_email) }

  let(:im) do
    FactoryBot.create(:incoming_message, raw_email: raw_email)
  end

  let(:to) { im.info_request.incoming_email }
  let(:from) { im.info_request.public_body.request_email }

  def populate_raw_email(fixture)
    mail = get_fixture_mail(fixture, to, from)
    raw_email.update!(data: mail)
  end

  it "should flatten all the attachments out" do
    populate_raw_email('incoming-request-oft-attachments.email')
    im.extract_attachments!

    expect(im.get_attachments_for_display.map(&:display_filename)).to eq([
      'test.html', # picks HTML rather than text by default, as likely to render better
      'attach.txt'
    ])
  end
end

RSpec.describe IncomingMessage, "when TNEF attachments are attached to messages" do
  let(:raw_email) { FactoryBot.create(:raw_email) }

  let(:im) do
    FactoryBot.create(:incoming_message, raw_email: raw_email)
  end

  let(:to) { im.info_request.incoming_email }
  let(:from) { im.info_request.public_body.request_email }

  def populate_raw_email(fixture)
    mail = get_fixture_mail(fixture, to, from)
    raw_email.update!(data: mail)
  end

  it "should flatten all the attachments out" do
    populate_raw_email('incoming-request-tnef-attachments.email')
    im.extract_attachments!

    expect(im.get_attachments_for_display.map(&:display_filename)).to eq([
      'FOI 09 02976i.doc',
      'FOI 09 02976iii.doc'
    ])
  end

  it 'does not attempt to save null bytes to the database' do
    populate_raw_email('incoming-request-tnef-only.email')
    im.extract_attachments!

    expect { im.get_main_body_text_unfolded }.not_to raise_error
    expect { im.get_main_body_text_folded }.not_to raise_error
    expect { im.cached_attachment_text_clipped }.not_to raise_error
  end

end

RSpec.describe IncomingMessage, "when extracting attachments" do

  before do
    load_raw_emails_data
  end

  it 'handles the case where reparsing changes the body of the main part
        and the cached attachment has been deleted' do
    # original set of attachment attributes
    attachment_attributes = { url_part_number: 1,
                              within_rfc822_subject: nil,
                              content_type: "text/plain",
                              charset: nil,
                              body: "No way!\n",
                              hexdigest: "0c8b1b0f5cb9c94ed15a180e73b5c7d1",
                              filename: nil }

    # Make a small change in the body returned for the attachment
    new_attachment_attributes = attachment_attributes.merge(body: "No way!",
                                                            hexdigest: "74d2c0a41e074f9cebe49324d5b47414")


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
    im = incoming_messages(:useless_incoming_message)
    allow(im).to receive(:extract_text).and_return("\xBF")

    expect(im._get_attachment_text_internal.valid_encoding?).to be true
  end

end

RSpec.describe IncomingMessage, 'when getting the body of a message for html display' do
  let(:incoming_message) { IncomingMessage.new }

  it 'should replace any masked email addresses with a link to the help page' do
    body_text = 'there was an [email address] here'
    allow(incoming_message).to receive(:get_main_body_text_folded).
      and_return(body_text)
    allow(incoming_message).to receive(:get_main_body_text_unfolded).
      and_return(body_text)

    expected = '<p>there was an [<a href="/help/officers#mobiles">email ' \
               'address</a>] here</p>'
    expect(incoming_message.get_body_for_html_display).to eq(expected)
  end

  it "interprets single line breaks as <br> tags" do
    body_text = "Hello,\nI am a test message\nWith multiple lines"
    allow(incoming_message).to receive(:get_main_body_text_folded).
      and_return(body_text)
    allow(incoming_message).to receive(:get_main_body_text_unfolded).
      and_return(body_text)

    expected = "<p>Hello,\n<br />I am a test message\n<br />With " \
               "multiple lines</p>"
    expect(incoming_message.get_body_for_html_display).to include(expected)
  end

  it "interprets double line breaks as <p> tags" do
    body_text = "Hello,\n\nI am a test message\n\nWith multiple lines"
    allow(incoming_message).to receive(:get_main_body_text_folded).
      and_return(body_text)
    allow(incoming_message).to receive(:get_main_body_text_unfolded).
      and_return(body_text)

    expected = "<p>Hello,</p>\n\n<p>I am a test message</p>\n\n<p>With " \
               "multiple lines</p>"
    expect(incoming_message.get_body_for_html_display).to include(expected)
  end

  it "removes excess linebreaks" do
    body_text = "Line 1\n\n\n\n\n\n\n\n\n\nLine 2"
    allow(incoming_message).to receive(:get_main_body_text_folded).
      and_return(body_text)
    allow(incoming_message).to receive(:get_main_body_text_unfolded).
      and_return(body_text)

    expected = "<p>Line 1</p>\n\n<p>Line 2</p>"
    expect(incoming_message.get_body_for_html_display).to include(expected)
  end

end

RSpec.describe IncomingMessage, 'when getting clipped attachment text' do

  it 'should clip to characters not bytes' do
    incoming_message = FactoryBot.build(:incoming_message)
    # This character is 2 bytes so the string should get sliced unless
    # we are handling multibyte chars correctly
    multibyte_string = "å" * 500_002
    allow(incoming_message).to receive(:_get_attachment_text_internal).and_return(multibyte_string)
    expect(incoming_message.get_attachment_text_clipped.length).to eq(500_002)
  end

end

RSpec.describe IncomingMessage, 'when getting the main body text' do

  context 'when the main body text is more than 1MB' do

    before do
      @incoming_message = FactoryBot.create(:incoming_message)
      allow(@incoming_message).to receive(:get_main_body_text_internal).
        and_return("x" * 1_000_010)
    end

    it 'raises an exception' do
      expected_text = "main body text more than 1 MB, need " \
                      "to implement clipping like for attachment " \
                      "text, or there is some other MIME decoding " \
                      "problem or similar"
      expect { @incoming_message.get_main_body_text_unfolded }.
        to raise_error(RuntimeError, expected_text)
    end

  end

end
