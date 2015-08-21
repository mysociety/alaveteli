# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WidgetHelper do

  include WidgetHelper

  describe '#status_description' do

    before do
      @info_request = FactoryGirl.build(:info_request)
    end

    it 'should return "Awaiting classification" for "waiting_classification' do
      expect(status_description(@info_request, 'waiting_classification')).to eq('Awaiting classification')
    end

    it 'should call theme_display_status for a theme status' do
      allow(@info_request).to receive(:theme_display_status).and_return("Special status")
      expect(status_description(@info_request, 'special_status')).to eq('Special status')
    end

    it 'should return unknown for an unknown status' do
      expect(status_description(@info_request, 'special_status')).to eq('Unknown')
    end

  end

end
