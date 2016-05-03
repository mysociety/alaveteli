# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RequestGameController do

  describe "GET play" do

    it "shows the game homepage" do
      get :play
      expect(response).to render_template('play')
    end
  end
end

