require 'spec_helper'

RSpec.describe InfoRequestExpireJob, type: :job do
  let(:args) { [] }
  subject(:perform) { described_class.new.perform(*args) }

  let(:request_1) { FactoryBot.build(:info_request) }
  let(:request_2) { FactoryBot.build(:info_request) }

  context 'when called with a request' do
    let(:args) { [request_1] }

    it 'calls expire on the request' do
      expect(request_1).to receive(:expire)
      perform
    end
  end

  context 'when called with an object with a info_requests association' do
    let(:user) do
      FactoryBot.build(:user, info_requests: [request_1, request_2])
    end

    let(:args) { [user, :info_requests] }

    it 'calls expire on the associated requests' do
      association = double(klass: InfoRequest)
      allow(user).to receive(:association).with(:info_requests).
        and_return(association)
      allow(association).to receive_message_chain(:reader, :find_each).
        and_yield(request_1).and_yield(request_2)

      expect(request_1).to receive(:expire)
      expect(request_2).to receive(:expire)
      perform
    end
  end

  context 'when called with the InfoRequest class' do
    let(:args) { [InfoRequest, :all] }

    it 'calls expire on the all requests' do
      allow(InfoRequest).to receive_message_chain(:all, :find_each).
        and_yield(request_1).and_yield(request_2)

      expect(request_1).to receive(:expire)
      expect(request_2).to receive(:expire)
      perform
    end
  end
end
