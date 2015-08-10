# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AdminSpamAddressesController do
  render_views
  before { basic_auth_login @request }

  describe 'GET index' do

    it 'lists the spam addresses' do
      3.times { FactoryGirl.create(:spam_address) }
      get :index
      expect(assigns(:spam_addresses)).to eq(SpamAddress.all)
    end

    it 'creates a new spam address for the form' do
      get :index
      expect(assigns(:spam_address)).to be_a_new(SpamAddress)
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template('index')
    end

  end

  describe 'POST create' do

    let(:spam_params) { FactoryGirl.attributes_for(:spam_address) }

    it 'creates a new spam address with the given parameters' do
      post :create, :spam_address => spam_params
      expect(assigns(:spam_address).email).to eq(spam_params[:email])
      expect(assigns(:spam_address)).to be_persisted
    end

    it 'redirects to the index action if successful' do
      allow_any_instance_of(SpamAddress).to receive(:save).and_return(true)
      post :create, :spam_address => spam_params
      expect(response).to redirect_to(admin_spam_addresses_path)
    end

    it 'notifies the admin the spam address has been created' do
      allow_any_instance_of(SpamAddress).to receive(:save).and_return(true)
      post :create, :spam_address => spam_params
      msg = "#{ spam_params[:email] } has been added to the spam addresses list"
      expect(flash[:notice]).to eq(msg)
    end

    it 'renders the index action if the address could not be saved' do
      allow_any_instance_of(SpamAddress).to receive(:save).and_return(false)
      post :create, :spam_address => spam_params
      expect(response).to render_template('index')
    end

    it 'collects the spam addresses if the address could not be saved' do
      3.times { FactoryGirl.create(:spam_address) }
      allow_any_instance_of(SpamAddress).to receive(:save).and_return(false)
      post :create, :spam_address => spam_params
      expect(assigns(:spam_addresses)).to eq(SpamAddress.all)
    end

  end

  describe 'DELETE destroy' do

    before(:each) do
      @spam = FactoryGirl.create(:spam_address)
      delete :destroy, :id => @spam.id
    end

    it 'finds the spam address to delete' do
      expect(assigns(:spam_address)).to eq(@spam)
    end

    it 'destroys the spam address' do
      expect(assigns(:spam_address)).to be_destroyed
    end

    it 'tells the admin the spam address has been deleted' do
      msg = "#{ @spam.email } has been removed from the spam addresses list"
      expect(flash[:notice]).to eq(msg)
    end

    it 'redirects to the index action' do
      expect(response).to redirect_to(admin_spam_addresses_path)
    end

  end

end
