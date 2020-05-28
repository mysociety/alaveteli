require 'spec_helper'

RSpec.shared_context 'Project::Queue context' do
  let(:project) do
    FactoryBot.create(:project,
                      contributors_count: 2,
                      classifiable_requests_count: 2,
                      extractable_requests_count: 2)
  end

  let(:current_user) { project.contributors.last }

  let(:session) { {} }

  let(:queue) { described_class.new(project, current_user, session) }
end


RSpec.shared_examples 'Project::Queue' do
  describe '#==' do
    subject { queue == other_queue }

    context 'when the queue is the same' do
      let(:other_queue) { described_class.new(project, current_user, session) }
      it { is_expected.to eq(true) }
    end

    context 'with a different project' do
      let(:other_queue) { described_class.new(double, current_user, session) }
      it { is_expected.to eq(false) }
    end

    context 'with a different user' do
      let(:other_queue) { described_class.new(project, double, session) }
      it { is_expected.to eq(false) }
    end

    context 'with a different session' do
      let(:other_queue) { described_class.new(project, current_user, double) }
      it { is_expected.to eq(false) }
    end
  end

  describe '#current' do
    subject { queue.current(1) }
    it { is_expected.to eq(1) }
  end

  describe '#clear_current' do
    subject { queue.clear_current }
    it { is_expected.to be_nil }
  end
end
