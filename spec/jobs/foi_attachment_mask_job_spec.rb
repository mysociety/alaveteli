require 'spec_helper'

RSpec.describe FoiAttachmentMaskJob, type: :job do
  let(:info_request) { FactoryBot.create(:info_request_with_html_attachment) }
  let(:incoming_message) { info_request.incoming_messages.first }
  let(:attachment) { incoming_message.foi_attachments.last }
  let(:body) { described_class.new.perform(attachment) }

  before { rebuild_raw_emails(info_request) }

  it 'sanitises HTML attachments' do
    # Nokogiri adds the meta tag; see
    # https://github.com/sparklemotion/nokogiri/issues/1008
    expected = <<-EOF.squish
    <!DOCTYPE html>
    <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
      </head>
      <body>dull
      </body>
    </html>
    EOF

    expect(body.squish).to eq(expected)
  end

  it 'censors attachments downloaded directly' do
    info_request.censor_rules.create!(
      text: 'dull', replacement: 'Boy',
      last_edit_editor: 'unknown', last_edit_comment: 'none'
    )
    expect(body).to_not include 'dull'
    expect(body).to include 'Boy'
  end

  it 'censors with rules on the user (rather than the request)' do
    info_request.user.censor_rules.create!(
      text: 'dull', replacement: 'Mole',
      last_edit_editor: 'unknown', last_edit_comment: 'none'
    )
    expect(body).to_not include 'dull'
    expect(body).to include 'Mole'
  end

  it 'censors with rules on the public body (rather than the request)' do
    info_request.public_body.censor_rules.create!(
      text: 'dull', replacement: 'Fox',
      last_edit_editor: 'unknown', last_edit_comment: 'none'
    )
    expect(body).to_not include 'dull'
    expect(body).to include 'Fox'
  end

  it 'censors with rules globally (rather than the request)' do
    CensorRule.create!(
      text: 'dull', replacement: 'Horse',
      last_edit_editor: 'unknown', last_edit_comment: 'none'
    )
    expect(body).to_not include 'dull'
    expect(body).to include 'Horse'
  end
end
