require 'spec_helper'
require 'models/project/queue_spec'

RSpec.describe Project::Queue::Classifiable do
  include_context 'Project::Queue context'

  it_behaves_like 'Project::Queue'

  shared_context 'with a current request' do
    let(:session) do
      {
        'projects' => {
          project.id.to_s => {
            'classifiable' => {
              'current' => current_request.id.to_s }
            }
        }
      }
    end
  end

  describe '#next' do
    subject { queue.next }

    context 'with a current request that can be classified' do
      include_context 'with a current request'
      let(:current_request) { project.info_requests.classifiable.last }
      it { is_expected.to eq(current_request) }
    end

    context 'with a current request that gets classified elsewhere' do
      include_context 'with a current request'
      let(:current_request) { project.info_requests.classifiable.last }
      before { current_request.update(awaiting_description: false) }

      it { is_expected.to be_a(InfoRequest) }
      it { is_expected.not_to eq(current_request) }
    end

    context 'without a current request' do
      before { queue.clear_current }
      it { is_expected.to be_a(InfoRequest) }
    end

    context 'when there are no requests left in the queue' do
      before { 2.times { queue.next.update(awaiting_description: false) } }
      it { is_expected.to be_nil }
    end

    it 'only includes classifiable requests' do
      classifiable = project.info_requests.classifiable.to_a

      requests = classifiable.size.times.map do
        request = queue.next
        request.update(awaiting_description: false)
        request
      end

      expect(queue.next).to be_nil
      expect(requests).to match_array(classifiable)
    end
  end

  describe '#include?' do
    subject { queue.include?(info_request) }

    context 'when the request is in the queue' do
      let(:info_request) { project.info_requests.classifiable.first }
      it { is_expected.to eq(true) }
    end

    context 'when the request is not in the queue' do
      let(:info_request) { FactoryBot.create(:info_request) }
      it { is_expected.to eq(false) }
    end
  end
end
