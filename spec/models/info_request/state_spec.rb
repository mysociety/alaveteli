# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe InfoRequest::State do

  describe :all do

    it 'includes "waiting_response"' do
      expect(InfoRequest::State.all.include?("waiting_response"))
        .to be true
    end

  end

  describe :phases do

    it 'returns an array' do
      expect(InfoRequest::State.phases).to be_a Array
    end

    it 'includes a hash with name "Complete" and scope :complete' do
      expect(InfoRequest::State.phases.include?({ name: _('Complete'),
                                                  scope: :complete }))
    end

  end
end
