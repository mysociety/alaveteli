require 'spec_helper'

RSpec.describe Workflow do
  let(:resource) { FactoryBot.build(:foi_attachment) }

  describe '.chunking' do
    it 'creates a new Workflow instance with chunking jobs' do
      workflow = Workflow.chunking(resource)
      expect(workflow).to be_a(Workflow)
      expect(workflow.jobs.map(&:class)).to eq(
        [
          Workflow::Jobs::ConvertToText,
          Workflow::Jobs::AnonymizeText,
          Workflow::Jobs::CreateChunks
        ]
      )
    end
  end

  describe '#initialize' do
    let(:jobs) { [Workflow::Jobs::ConvertToText] }
    let(:workflow) { Workflow.new(resource: resource, jobs: jobs) }

    it 'sets the resource and jobs' do
      expect(workflow.instance_variable_get(:@resource)).to eq(resource)
      expect(workflow.instance_variable_get(:@klasses)).to eq(jobs)
    end
  end

  describe '#run' do
    let(:workflow) { Workflow.chunking(resource) }
    let(:last_job) { workflow.jobs.last }

    context 'when the last job is completed' do
      before { allow(last_job).to receive(:completed?).and_return(true) }

      it 'does not run any job' do
        expect(workflow).not_to receive(:run_job)
        workflow.run
      end
    end

    context 'when the last job is not completed' do
      before { allow(last_job).to receive(:completed?).and_return(false) }

      it 'runs the last job' do
        expect(workflow).to receive(:run_job).with(last_job.class)
        workflow.run
      end
    end
  end

  describe '#run_job' do
    let(:workflow) { Workflow.chunking(resource) }
    let(:job_class) { Workflow::Jobs::ConvertToText }

    it 'queues, runs, and resets jobs as needed' do
      initial_job = double('initial_job', pending!: true, run: true)
      job_to_queue = double('job_to_queue', queued!: true)
      job_to_reset = double('job_to_reset', reset!: true)

      allow(workflow).to receive(:plan_workflow).
        and_return([initial_job, [job_to_queue], [job_to_reset]])

      expect(initial_job).to receive(:pending!)
      expect(initial_job).to receive(:run)
      expect(job_to_queue).to receive(:queued!)
      expect(job_to_reset).to receive(:reset!)

      workflow.run_job(job_class)
    end
  end

  describe '#jobs' do
    let(:workflow) { Workflow.chunking(resource) }

    it 'returns an array of job instances' do
      expect(workflow.jobs).to all(be_a(Workflow::Job))
    end

    it 'sets the correct parent for each job' do
      jobs = workflow.jobs
      expect(jobs[1].parent).to eq(jobs[0])
      expect(jobs[2].parent).to eq(jobs[1])
    end
  end
end
