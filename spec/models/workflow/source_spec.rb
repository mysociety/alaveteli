require 'spec_helper'

RSpec.describe Workflow::Source do
  let(:dummy_class) do
    Class.new(Workflow::Job) do
      include Workflow::Source
      attr_accessor :parent, :resource, :completed, :content_type

      def self.name
        'DummyClass'
      end

      def completed?
        completed
      end
    end
  end

  let(:job) { dummy_class.new }

  describe 'associations' do
    it 'has one attached output' do
      expect(job.output).to be_an_instance_of(ActiveStorage::Attached::One)
    end
  end

  describe 'validations' do
    context 'when completed' do
      before do
        job.completed = true
      end

      it 'requires output' do
        job.output = nil
        expect(job).not_to be_valid
      end
    end

    context 'when not completed' do
      before do
        job.completed = false
      end

      it 'does not require output' do
        job.output = nil
        expect(job).to be_valid
      end
    end
  end

  describe '#source' do
    context 'when parent is completed' do
      let(:parent) { double('parent', completed?: true, output: double) }
      let(:file_content) { 'File content' }

      before do
        job.parent = parent
        allow(parent.output).to receive(:open).
          and_yield(StringIO.new(file_content))
      end

      it 'returns the parent output content' do
        expect(job.source.to_s).to eq(file_content)
      end
    end

    context 'when parent is not completed' do
      let(:resource) { double('resource', chunk_text: 'Resource text') }

      before do
        job.parent = nil
        job.resource = resource
      end

      it 'returns the resource chunk_text' do
        expect(job.source).to eq('Resource text')
      end
    end
  end

  describe '#source=' do
    let(:resource) { double('resource', class: 'ResourceClass', id: 123) }
    let(:string) { 'New source content' }

    before do
      job.resource = resource
      job.content_type = 'text/plain'
    end

    it 'sets the source job variable' do
      job.source = string
      expect(job.instance_variable_get(:@source)).to eq(string)
    end

    it 'attaches the string as output' do
      expect(job.output).to receive(:attach).with(
        io: an_instance_of(StringIO),
        filename: job.send(:filename),
        content_type: job.send(:content_type)
      )
      job.source = string
    end
  end

  describe '#filename' do
    let(:resource) { double('resource', class: 'ResourceClass', id: 123) }

    before do
      job.resource = resource
    end

    it 'returns the correct filename format' do
      expect(job.send(:filename)).to eq('ResourceClass-123-DummyClass')
    end
  end
end
