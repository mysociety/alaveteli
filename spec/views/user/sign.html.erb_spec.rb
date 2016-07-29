# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe 'user/sign' do
  describe 'when a not logged in user is redirected while trying to track a request' do
    before do
      html_title = "test's \"title\" of many HTML tags &c"
      @rendered_title = 'test&#39;s &quot;title&quot; of many HTML tags &amp;c'
      request = FactoryGirl.create(:info_request, :title => html_title)
      tracker = FactoryGirl.create(:request_update_track,
                                   :info_request => request,
                                   :track_medium => 'email_daily',
                                   :track_query => 'test')
      redirect = PostRedirect.create(:uri => '/request/test',
                                     :post_params => {},
                                     :reason_params => tracker.params)
      assign :post_redirect, redirect
    end

    it 'should show the first form for describing the state of the request' do
      render
      expect(response).to match("To follow the request &#39;#{@rendered_title}&#39;")
    end
  end

  describe 'when the requested URI is for an admin page and an emergency user exists' do

    before do
      redirect = PostRedirect.create(:uri => 'http://bad.place.com/admin',
                                     :post_params => {'controller' => 'admin_general'},
                                     :reason_params => {:web => '',
                                                        :user_name => 'Admin user',
                                                        :user_url => 'users/admin_user'})
      receive(:disable_emergency_user).and_return(false)
      assign :post_redirect, redirect
    end

    it 'shows a link to the path with an emergency param added' do
      render
      expect(response).to include("/admin?emergency=1")
    end

    it 'does not show a link to a different domain' do
      render
      expect(response).not_to include("http://bad.place.com/admin?emergency=1")
    end

  end

end
