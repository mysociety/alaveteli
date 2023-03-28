require 'integration/alaveteli_dsl'

RSpec.shared_context 'prominence context' do
  let!(:event) do
    FactoryBot.create(
      :response_event,
      info_request: info_request,
      incoming_message: incoming_message
    )
  end

  let(:info_request) { FactoryBot.create(:info_request) }

  let(:incoming_message) do
    FactoryBot.create(:incoming_message, info_request: info_request)
  end

  let(:attachment) do
    FactoryBot.create(
      :html_attachment,
      body: 'dull',
      incoming_message: incoming_message
    )
  end

  let(:requester) { info_request.user }
  let(:other_user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin_user) }
end

module AlaveteliPromienceDsl
  def self.included(base)
    base.include_context 'prominence context'
  end

  def hide_info_request(prominence = 'hidden')
    info_request.update(prominence: prominence)
  end

  def hide_incoming_message(prominence = 'hidden')
    incoming_message.update(prominence: prominence)
  end

  def hide_main_body_part(prominence = 'hidden')
    main_body_part.update(prominence: prominence)
  end

  def hide_attachment(prominence = 'hidden')
    attachment.update(prominence: prominence)
  end

  def guest_session(&block)
    @guest_id ||= without_login
    using_session(@guest_id) do
      within_session.call
      block.call
    end
  end

  def requester_session(&block)
    @requester_id ||= login(requester)
    using_session(@requester_id) do
      within_session.call
      block.call
    end
  end

  def other_user_session(&block)
    @other_user_id ||= login(other_user)
    using_session(@other_user_id) do
      within_session.call
      block.call
    end
  end

  def admin_session(&block)
    @admin_id ||= login(admin)
    using_session(@admin_id) do
      within_session.call
      block.call
    end
  end
end
