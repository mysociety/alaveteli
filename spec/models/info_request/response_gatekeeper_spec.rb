# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe InfoRequest::ResponseGatekeeper do

  describe '.for' do

    it 'returns a new ResponseGatekeeper for known gatekeepers' do
      const = 'InfoRequest::ResponseGatekeeper::SPECIALIZED_CLASSES'
      specialized_classes = { 'known' => described_class::Base,
                              'nobody' => described_class::Nobody }
      stub_const(const, specialized_classes)
      info_request = double('info_request')

      expect(described_class::Base).
        to receive(:new).with(info_request).and_call_original
      expect(described_class.for('known', info_request)).
        to be_an_instance_of(described_class::Base)
    end

    it 'raises an error if there is no response gatekeeper' do
      const = 'InfoRequest::ResponseGatekeeper::SPECIALIZED_CLASSES'
      err = described_class::UnknownResponseGatekeeperError
      stub_const(const, {})
      expect{ described_class.for('unknown', double('info_request')) }.
        to raise_error(err)
    end

  end

end
