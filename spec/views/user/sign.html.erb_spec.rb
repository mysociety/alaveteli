# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe 'user/sign' do
  describe 'when a not logged in user is redirected while trying to track a request' do
    before do
      html_title = "test&#x27;s &quote;title&quote; of many HTML tags &amp;c"
      @rendered_title = 'test\'s &quote;title&quote; of many HTML tags &amp;c'

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
      expect(response).to have_content("To follow the request '#{@rendered_title}'")
    end
  end
end
