# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RequestGameController, "when playing the game" do
  before(:each) do
    load_raw_emails_data
  end

  it "should show the game homepage" do
    get :play
    expect(response).to render_template('play')
  end
end

