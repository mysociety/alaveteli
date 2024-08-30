require 'spec_helper'

RSpec.describe InfoRequest, Chunkable do
  let(:record) { FactoryBot.build(:info_request) }

  describe 'associations' do
    it 'has many chunks' do
      expect(record.chunks).to all be_a(Chunk)
    end
  end

  describe '#chunk!' do
    it 'calls chunk_delegate!' do
      expect(record).to receive(:chunk_delegate!)
      record.chunk!
    end
  end

  describe '#chunk_text' do
    it 'returns nil when the column is not configured' do
      expect(record.chunk_text).to be_nil
    end
  end

  describe '#chunk_delegate!' do
    it 'calls chunk! on each associated incoming_messages' do
      associated_record = double('associated_record')
      expect(record).to receive(:incoming_messages).
        and_return([associated_record])
      expect(associated_record).to receive(:chunk!)
      record.chunk_delegate!
    end
  end

  describe '#chunk_assoications' do
    it 'returns an empty hash when no association is found' do
      expect(record.chunk_assoications).to eq({})
    end
  end
end

RSpec.describe IncomingMessage, Chunkable do
  let(:record) { FactoryBot.build(:incoming_message) }

  describe 'associations' do
    it 'has many chunks' do
      expect(record.chunks).to all be_a(Chunk)
    end
  end

  describe '#chunk!' do
    it 'calls chunk_workflow.run when chunk_text is present' do
      workflow = double('workflow')
      expect(record).to receive(:chunk_workflow).and_return(workflow)
      expect(workflow).to receive(:run)
      expect(record).to receive(:chunk_text).and_return('Some text')
      expect(record).to receive(:chunk_delegate!)
      record.chunk!
    end

    it 'calls chunk_delegate! even when chunk_text is nil' do
      expect(record).to receive(:chunk_text).and_return(nil)
      expect(record).to receive(:chunk_delegate!)
      record.chunk!
    end
  end

  describe '#chunk_text' do
    it 'returns the value of the configured column' do
      expect(record).to receive(:cached_main_body_text_folded).
        and_return('Some content')
      expect(record.chunk_text).to eq('Some content')
    end
  end

  describe '#chunk_delegate!' do
    it 'calls chunk! on each associated foi_attachments' do
      associated_record = double('associated_record')
      expect(record).to receive(:foi_attachments).
        and_return([associated_record])
      expect(associated_record).to receive(:chunk!)
      record.chunk_delegate!
    end
  end

  describe '#chunk_assoications' do
    it 'returns an hash with parent info_request' do
      assoications = record.chunk_assoications
      expect(assoications).to include(info_request: record.info_request)
    end
  end
end

RSpec.describe FoiAttachment, Chunkable do
  let(:record) do
    FactoryBot.build(
      :foi_attachment, incoming_message: FactoryBot.build(:incoming_message)
    )
  end

  describe 'associations' do
    it 'has many chunks' do
      expect(record.chunks).to all be_a(Chunk)
    end
  end

  describe '#chunk!' do
    it 'calls chunk_workflow.run when chunk_text is present' do
      workflow = double('workflow')
      expect(record).to receive(:chunk_workflow).and_return(workflow)
      expect(workflow).to receive(:run)
      expect(record).to receive(:chunk_text).and_return('Some text')
      expect(record).to receive(:chunk_delegate!)
      record.chunk!
    end

    it 'calls chunk_delegate! even when chunk_text is nil' do
      expect(record).to receive(:chunk_text).and_return(nil)
      expect(record).to receive(:chunk_delegate!)
      record.chunk!
    end
  end

  describe '#chunk_text' do
    it 'returns the value of the configured column' do
      expect(record).to receive(:body_as_html).and_return('Some content')
      expect(record.chunk_text).to eq('Some content')
    end
  end

  describe '#chunk_delegate!' do
    it 'does nothing when delegate_to is not configured' do
      allow(record).to receive(:chunkable_config).and_return({})
      expect { record.chunk_delegate! }.not_to raise_error
    end
  end

  describe '#chunk_assoications' do
    it 'returns an hash with parent incoming_message and info_request' do
      assoications = record.chunk_assoications
      expect(assoications).to include(
        info_request: record.info_request,
        incoming_message: record.incoming_message
      )
    end
  end
end
