# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe InfoRequest::ResponseRejection do

  describe '.for' do

    it 'returns a new ResponseRejection for known rejections' do
      const = 'InfoRequest::ResponseRejection::SPECIALIZED_CLASSES'
      specialized_classes = { 'known' => described_class::Base,
                              'bounce' => described_class::Bounce }
      stub_const(const, specialized_classes)
      args = [double('info_request'), double('email'), double('raw_email_data')]

      expect(described_class::Base).
        to receive(:new).with(*args).and_call_original
      expect(described_class.for('known', *args)).
        to be_an_instance_of(described_class::Base)
    end

    it 'raises an error if there is no response rejection' do
      const = 'InfoRequest::ResponseRejection::SPECIALIZED_CLASSES'
      err = described_class::UnknownResponseRejectionError
      stub_const(const, {})
      args = [double('info_request'), double('email'), double('raw_email_data')]

      expect{ described_class.for('unknown', *args) }.
        to raise_error(err)
    end

  end

end
