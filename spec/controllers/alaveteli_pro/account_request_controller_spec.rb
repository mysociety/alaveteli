# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliPro::AccountRequestController do

  describe "#new" do
    it "renders new.html.erb" do
      with_feature_enabled :alaveteli_pro do
        get :new
        expect(response).to render_template('new')
      end
    end
  end

  describe "#create" do
  end

end
