# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe "When sending track alerts" do

  it "should send alerts" do

    info_request = FactoryGirl.create(:info_request)
    user = FactoryGirl.create(:user, :last_daily_track_email => 3.days.ago)
    user_session = login(user)
    using_session(user_session) do
      visit "track/request/#{info_request.url_title}"
    end

    other_user = FactoryGirl.create(:user)
    other_user_session = login(other_user)
    using_session(other_user_session) do
      visit "en/annotate/request/#{info_request.url_title}"
      fill_in "comment[body]", :with => 'test comment'
      click_button 'Preview your annotation'
      click_button 'Post annotation'
    end

    rebuild_xapian_index

    TrackMailer.alert_tracks

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(1)
    mail = deliveries[0]
    expect(mail.body).to match(/Alter your subscription/)
    expect(mail.to_addrs.first.to_s).to include(user.email)
    mail.body.to_s =~ /(http:\/\/.*\/c\/(.*))/
    mail_url = $1
    mail_token = $2

    expect(mail.body).not_to match(/&amp;/)

    expect(mail.body).not_to include('sent a request') # request not included
    expect(mail.body).not_to include('sent a response') # response not included
    expect(mail.body).to include('added an annotation') # comment included

    expect(mail.body).to match(/test comment/) # comment text included

    post_redirect = PostRedirect.find_by_email_token(mail_token)
    expected_path = show_user_path(:url_name => user.url_name,
                                   :anchor => "email_subscriptions")
    expect(post_redirect.uri).to match(expected_path)

    # Check nothing more is delivered if we try again
    deliveries.clear
    TrackMailer.alert_tracks
    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(0)
  end

  it "should send localised alerts" do
    info_request = FactoryGirl.create(:info_request)
    user = FactoryGirl.create(:user, :last_daily_track_email => 3.days.ago,
                                     :locale => 'es')
    user_session = login(user)
    using_session(user_session) do
      visit "es/track/request/#{info_request.url_title}"
    end

    other_user = FactoryGirl.create(:user, :locale => 'en')
    other_user_session = login(other_user)
    using_session(other_user_session) do
      visit "annotate/request/#{info_request.url_title}"
      fill_in "comment[body]", :with => 'test comment'
      click_button 'Preview your annotation'
      click_button 'Post annotation'
    end

    rebuild_xapian_index

    TrackMailer.alert_tracks
    deliveries = ActionMailer::Base.deliveries
    mail = deliveries[0]
    expect(mail.body).to include('el equipo de ')
  end
end

