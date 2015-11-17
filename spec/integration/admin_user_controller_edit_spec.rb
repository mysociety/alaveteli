# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'Editing a User' do
  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)

    confirm(:admin_user)
    @admin = login(:admin_user)

    @user = FactoryGirl.create(:user,
                               :name => 'nasty user 123',
                               :ban_text => 'You are banned')
  end

  context 'when a user is banned' do

    it 're-editing does not change their url_name' do
      using_session(@admin) do
        visit edit_admin_user_path(@user)
        fill_in 'admin_user_ban_text', :with => 'You are really banned'
        click_button 'Save'
      end

      expect(@user.reload.url_name).to eq('nasty_user_123')
    end

  end

end
