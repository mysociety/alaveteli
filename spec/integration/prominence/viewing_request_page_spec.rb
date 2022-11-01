require 'spec_helper'
require 'integration/alaveteli_prominence_dsl'

RSpec.describe 'viewing request page with prominence', local_requsts: false do
  include AlaveteliPromienceDsl

  let(:within_session) do
    -> { visit "/request/#{info_request.url_title}" }
  end

  def hidden_request
    page.find(:id, 'hidden_request').text
  rescue Capybara::ElementNotFound
    ''
  end

  def hidden_message
    page.find(:id, "incoming-#{incoming_message.id}").
         find(:css, '.hidden_message').text
  rescue Capybara::ElementNotFound
    ''
  end

  def hidden_attachment
    page.find(:id, "attachment-#{attachment.id}").
         find(:css, '.hidden_attachment').text
  rescue Capybara::ElementNotFound
    ''
  end

  it 'when request, message and attachment are normal' do
    guest_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to be_empty
    end

    other_user_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to be_empty
    end

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to be_empty
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to be_empty
    end
  end

  it 'when request is hidden, message and attachment are normal' do
    hide_info_request

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to be_empty
    end
  end

  it 'when request is requester_only, message and attachment are normal' do
    hide_info_request('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request is hidden,
          so that only you, the requester, can see it.
        TXT
      )
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to be_empty
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to be_empty
    end
  end

  it 'when request and attachment are normal, message is requester_only' do
    hide_incoming_message('requester_only')

    guest_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    other_user_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message is hidden,
          so that only you, the requester, can see it.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end
  end

  it 'when request and message are requester_only, attachment is normal' do
    hide_info_request('requester_only')
    hide_incoming_message('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request is hidden,
          so that only you, the requester, can see it.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message is hidden,
          so that only you, the requester, can see it.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end
  end

  it 'when request is hidden, message is requester_only, attachment is normal' do
    hide_info_request
    hide_incoming_message('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end
  end

  it 'when request and attachment are normal, message is hidden' do
    hide_incoming_message

    guest_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    other_user_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end
  end

  it 'when request is requester_only, message is hidden, attachment is normal' do
    hide_info_request('requester_only')
    hide_incoming_message

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request is hidden,
          so that only you, the requester, can see it.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end
  end

  it 'when request and message is hidden, attachment is normal' do
    hide_info_request
    hide_incoming_message

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end
  end

  it 'when request and message is normal, attachment is requester_only' do
    hide_attachment('requester_only')

    guest_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has been hidden.
        TXT
      )
    end

    other_user_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has been hidden.
        TXT
      )
    end

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment is hidden,
          so that only you, the requester, can see it.
        TXT
      )
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request and attachment are requester_only, message is normal' do
    hide_info_request('requester_only')
    hide_attachment('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request is hidden,
          so that only you, the requester, can see it.
        TXT
      )
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment is hidden,
          so that only you, the requester, can see it.
        TXT
      )
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request is hidden, message is normal, attachment is requester_only' do
    hide_info_request
    hide_attachment('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request is normal, message and attachment are requester_only' do
    hide_incoming_message('requester_only')
    hide_attachment('requester_only')

    guest_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    other_user_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message is hidden,
          so that only you, the requester, can see it.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment is hidden,
          so that only you, the requester, can see it.
        TXT
      )
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request, message and attachment are requester_only' do
    hide_info_request('requester_only')
    hide_incoming_message('requester_only')
    hide_attachment('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request is hidden,
          so that only you, the requester, can see it.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message is hidden,
          so that only you, the requester, can see it.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment is hidden,
          so that only you, the requester, can see it.
        TXT
      )
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request is hidden, message and attachment is requester_only' do
    hide_info_request
    hide_incoming_message('requester_only')
    hide_attachment('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request is normal, message is hidden, attachment is requester_only' do
    hide_incoming_message
    hide_attachment('requester_only')

    guest_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    other_user_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request and attachment is requester_only, message is hidden' do
    hide_info_request('requester_only')
    hide_incoming_message
    hide_attachment('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request is hidden,
          so that only you, the requester, can see it.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request and message are hidden, attachment is requester_only' do
    hide_info_request
    hide_incoming_message
    hide_attachment('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request and message are normal, attachment is hidden' do
    hide_attachment

    guest_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has been hidden.
        TXT
      )
    end

    other_user_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has been hidden.
        TXT
      )
    end

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has been hidden.
        TXT
      )
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request is requester_only, message is normal, attachment is hidden' do
    hide_info_request('requester_only')
    hide_attachment

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request is hidden,
          so that only you, the requester, can see it.
        TXT
      )
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has been hidden.
        TXT
      )
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request and attachment are hidden, message is normal' do
    hide_info_request
    hide_attachment

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to be_empty
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request is normal, message is requester_only, attachment is hidden' do
    hide_incoming_message('requester_only')
    hide_attachment

    guest_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    other_user_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message is hidden,
          so that only you, the requester, can see it.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has been hidden.
        TXT
      )
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request and message are requester_only, attachment is hidden' do
    hide_info_request('requester_only')
    hide_incoming_message('requester_only')
    hide_attachment

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request is hidden,
          so that only you, the requester, can see it.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message is hidden,
          so that only you, the requester, can see it.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has been hidden.
        TXT
      )
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request and attachment are hidden, message is requester_only' do
    hide_info_request
    hide_incoming_message('requester_only')
    hide_attachment

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request is normal, message and attachment are hidden' do
    hide_incoming_message
    hide_attachment

    guest_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    other_user_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to be_empty
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request is requester_only, message and attachment are hidden' do
    hide_info_request('requester_only')
    hide_incoming_message
    hide_attachment

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }

    requester_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request is hidden,
          so that only you, the requester, can see it.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has been hidden.
        TXT
      )
      expect(hidden_attachment).to be_empty
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "requester_only".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end

  it 'when request, message and attachment are hidden' do
    hide_info_request
    hide_incoming_message
    hide_attachment

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(hidden_request).to include(
        <<~TXT.squish
          This request has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_message).to include(
        <<~TXT.squish
          This message has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
      expect(hidden_attachment).to include(
        <<~TXT.squish
          This attachment has prominence "hidden".
          You can only see it because you are logged in as a super user.
        TXT
      )
    end
  end
end
