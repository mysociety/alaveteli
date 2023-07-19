require 'spec_helper'
require 'integration/alaveteli_prominence_dsl'

RSpec.describe 'viewing raw attachment with prominence',
local_requests: false do
  include AlaveteliPromienceDsl

  let(:within_session) do
    -> {
      rebuild_raw_emails(info_request)

      visit get_attachment_url(
        incoming_message_id: attachment.incoming_message_id,
        part: attachment.url_part_number,
        file_name: attachment.display_filename,
        id: info_request.id
      )
    }
  end

  it 'when request, message and attachment are normal' do
    guest_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end

    other_user_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end

    requester_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end
  end

  it 'when request is hidden, message and attachment are normal' do
    hide_info_request

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end
  end

  it 'when request is requester_only, message and attachment are normal' do
    hide_info_request('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }

    requester_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end
  end

  it 'when request and attachment are normal, message is requester_only' do
    hide_incoming_message('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }

    requester_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end
  end

  it 'when request and message are requester_only, attachment is normal' do
    hide_info_request('requester_only')
    hide_incoming_message('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }

    requester_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
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
      expect(page.text).to eq('dull')
    end
  end

  it 'when request and attachment are normal, message is hidden' do
    hide_incoming_message

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end
  end

  it 'when request is requester_only, message is hidden, attachment is normal' do
    hide_info_request('requester_only')
    hide_incoming_message

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
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
      expect(page.text).to eq('dull')
    end
  end

  it 'when request and message is normal, attachment is requester_only' do
    hide_attachment('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }

    requester_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end
  end

  it 'when request and attachment are requester_only, message is normal' do
    hide_info_request('requester_only')
    hide_attachment('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }

    requester_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
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
      expect(page.text).to eq('dull')
    end
  end

  it 'when request is normal, message and attachment are requester_only' do
    hide_incoming_message('requester_only')
    hide_attachment('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }

    requester_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
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
      expect(page.text).to eq('dull')
    end

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
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
      expect(page.text).to eq('dull')
    end
  end

  it 'when request is normal, message is hidden, attachment is requester_only' do
    hide_incoming_message
    hide_attachment('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end
  end

  it 'when request and attachment is requester_only, message is hidden' do
    hide_info_request('requester_only')
    hide_incoming_message
    hide_attachment('requester_only')

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
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
      expect(page.text).to eq('dull')
    end
  end

  it 'when request and message are normal, attachment is hidden' do
    hide_attachment

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end
  end

  it 'when request is requester_only, message is normal, attachment is hidden' do
    hide_info_request('requester_only')
    hide_attachment

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
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
      expect(page.text).to eq('dull')
    end
  end

  it 'when request is normal, message is requester_only, attachment is hidden' do
    hide_incoming_message('requester_only')
    hide_attachment

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end
  end

  it 'when request and message are requester_only, attachment is hidden' do
    hide_info_request('requester_only')
    hide_incoming_message('requester_only')
    hide_attachment

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
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
      expect(page.text).to eq('dull')
    end
  end

  it 'when request is normal, message and attachment are hidden' do
    hide_incoming_message
    hide_attachment

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
    end
  end

  it 'when request is requester_only, message and attachment are hidden' do
    hide_info_request('requester_only')
    hide_incoming_message
    hide_attachment

    guest_session { expect(page.status_code).to eq(403) }
    other_user_session { expect(page.status_code).to eq(403) }
    requester_session { expect(page.status_code).to eq(403) }

    admin_session do
      expect(page.status_code).to eq(200)
      expect(page.text).to eq('dull')
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
      expect(page.text).to eq('dull')
    end
  end
end
