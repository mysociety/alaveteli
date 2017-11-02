# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AdminTrackController do

  describe 'GET index' do

    it "shows the index page" do
      get :index
      expect(response).to render_template("index")
    end

  end
end
