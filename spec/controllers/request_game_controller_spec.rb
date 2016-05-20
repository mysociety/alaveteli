# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RequestGameController do

  describe "GET play" do

    it "shows the game homepage" do
      get :play
      expect(response).to render_template('play')
    end

    it 'assigns three old unclassified requests' do
      InfoRequest.destroy_all
      requests = []
      3.times do
        requests << FactoryGirl.create(:old_unclassified_request)
      end
      get :play
      expect(assigns[:requests]).to match_array(requests)
    end

    it 'assigns the number of unclassified requests' do
      InfoRequest.destroy_all
      FactoryGirl.create(:old_unclassified_request)
      get :play
      expect(assigns[:missing]).to eq(1)
    end

  end
end

