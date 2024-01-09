require 'spec_helper'

RSpec.describe NotifyCacheJob, type: :job do
  let(:args) { [] }
  subject(:perform) { described_class.new.perform(*args) }
  subject(:enqueue) { described_class.perform_later(*args) }

  let(:request) { FactoryBot.build(:info_request) }
  let(:comment) { FactoryBot.build(:comment) }
  let(:attachment) { FactoryBot.build(:pdf_attachment) }
  let(:im) { FactoryBot.create(:plain_incoming_message) }
  let(:body) { FactoryBot.create(:public_body) }
  let(:user) { FactoryBot.create(:user) }

  before do
    @old_include_default_locale_in_urls =
      AlaveteliConfiguration.include_default_locale_in_urls
    AlaveteliLocalization.set_default_locale_urls(false)

    allow(AlaveteliConfiguration).to receive(:varnish_hosts).
      and_return(['varnish'])

    stub_request(:purge, /^http:\/\/test\.host(\/(en|es|fr|en_GB))?\/(|body|((feed\/)?body|request|(feed\/)?user)\/[a-z0-9_]+(\/feed|\/details)?|user\/[a-z0-9_]+\/wall)$/).
      to_return(status: 200, body: "", headers: {})
    stub_request(:ban, 'http://test.host/').
      with(headers:
        {
          'X-Invalidate-Pattern' =>
            /^\^(\/(en|es|fr|en_GB))?\/(list|feed\/list\/|body\/list)$/
        }).
      to_return(status: 200, body: "", headers: {})
  end

  after do
    AlaveteliLocalization.set_default_locale_urls(
      @old_include_default_locale_in_urls
    )
  end

  context 'when called with a request' do
    let(:args) { [request] }

    it 'calls out to varnish correctly' do
      expect(Rails.logger).to receive(:debug).exactly(55).times
      perform
    end
  end

  context 'when called with a comment' do
    let(:args) { [comment] }

    it 'calls out to varnish correctly' do
      expect(Rails.logger).to receive(:debug).exactly(10).times
      perform
    end
  end

  context 'when called with an attachment' do
    let(:args) { [attachment] }

    it 'calls out to varnish correctly' do
      attachment.incoming_message = im
      expect(Rails.logger).to receive(:debug).exactly(5).times
      perform
    end
  end

  context 'when called with a body' do
    let(:args) { [body] }

    it 'calls out to varnish correctly' do
      attachment.incoming_message = im
      expect(Rails.logger).to receive(:debug).exactly(15).times
      perform
    end
  end

  context 'when called with a user' do
    let(:args) { [user] }

    it 'calls out to varnish correctly' do
      attachment.incoming_message = im
      expect(Rails.logger).to receive(:debug).exactly(5).times
      perform
    end
  end

  context 'with varnish hosts configured' do
    let(:args) { [request] }

    before do
      allow(request).to receive(:id).and_return(1)
    end

    it 'enqueues the job' do
      expect(enqueue).to be_a(NotifyCacheJob)
    end
  end

  context 'without varnish hosts configured' do
    let(:args) { [request] }

    before do
      allow(AlaveteliConfiguration).to receive(:varnish_hosts).and_return(nil)
    end

    it 'does not enqueues the job' do
      expect(enqueue).to eq(false)
    end
  end
end
