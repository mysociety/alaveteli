require 'spec_helper'

RSpec.describe Workflow::Transitions do
  let(:dummy_class) do
    Class.new(Workflow::Job) do
      include Workflow::Transitions
      attr_accessor :source, :metadata

      def self.name
        'DummyClass'
      end

      def initialize(*args)
        @metadata = {}
        super
      end

      def valid?(*)
        true
      end

      def perform
        "Result"
      end
    end
  end

  let(:job) { dummy_class.new }

  describe 'included functionality' do
    it 'includes the enum for status' do
      expect(dummy_class.new).to respond_to(:status)
      expect(dummy_class.new).to respond_to(:pending?)
      expect(dummy_class.new).to respond_to(:queued?)
      expect(dummy_class.new).to respond_to(:processing?)
      expect(dummy_class.new).to respond_to(:failed?)
      expect(dummy_class.new).to respond_to(:completed?)
    end
  end

  describe '#run' do
    it 'calls process! when valid and not completed' do
      expect(job).to receive(:process!)
      job.run
    end

    it 'does not call process! when completed' do
      allow(job).to receive(:completed?).and_return(true)
      expect(job).not_to receive(:process!)
      job.run
    end

    it 'does not call process! when invalid' do
      allow(job).to receive(:valid?).and_return(false)
      expect(job).not_to receive(:process!)
      job.run
    end
  end

  describe '#perform!' do
    it 'sets source and calls complete! when successful' do
      expect(job).to receive(:complete!)
      job.perform!
      expect(job.source).to eq("Result")
    end

    it 'calls fail! when an exception is raised' do
      allow(job).to receive(:perform).and_raise(StandardError.new("Test error"))
      expect(job).to receive(:fail!)
      job.perform!
    end
  end

  describe '#reset!' do
    it 'calls destroy!' do
      expect(job).to receive(:destroy!)
      job.reset!
    end
  end

  describe '#process!' do
    it 'removes error and backtrace from metadata' do
      job.metadata[:error] = "Error"
      job.metadata[:backtrace] = ["Line 1", "Line 2"]
      job.send(:process!)
      expect(job.metadata[:error]).to be_nil
      expect(job.metadata[:backtrace]).to be_nil
    end

    it 'changes status to processing' do
      allow(job).to receive(:id).and_return(123)
      expect(job).to receive(:processing!)
      job.send(:process!)
    end

    it 'enqueues a WorkflowJob' do
      expect(WorkflowJob).to receive(:perform_later).with(job)
      job.send(:process!)
    end
  end

  describe '#fail!' do
    let(:exception) { StandardError.new("Test error") }

    it 'sets error and backtrace in metadata' do
      job.send(:fail!, exception)
      expect(job.metadata[:error]).to eq("Test error")
      expect(job.metadata[:backtrace]).to eq(exception.backtrace)
    end

    it 'changes status to failed' do
      expect(job).to receive(:failed!)
      job.send(:fail!, exception)
    end
  end

  describe '#complete!' do
    it 'removes error and backtrace from metadata' do
      job.metadata[:error] = "Error"
      job.metadata[:backtrace] = ["Line 1", "Line 2"]
      job.send(:complete!)
      expect(job.metadata[:error]).to be_nil
      expect(job.metadata[:backtrace]).to be_nil
    end

    it 'changes status to completed' do
      expect(job).to receive(:completed!)
      job.send(:complete!)
    end

    it 'processes the next queued job if exists' do
      next_job = FactoryBot.build(:workflow_job)
      allow(Workflow::Job).to receive_message_chain(:queued, :find_by).
        and_return(next_job)
      expect(next_job).to receive(:process!)
      job.send(:complete!)
    end
  end
end
