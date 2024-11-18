require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe "When sending track alerts" do
  before do
    # TODO: required to make sure xapian index can find files for raw emails
    # associated with fixtures - can be removed when fixtures no longer
    # automatically loaded for all specs
    load_raw_emails_data
    update_xapian_index
  end

  it "should send alerts" do
    info_request = FactoryBot.create(:info_request)
    user = FactoryBot.create(:user, last_daily_track_email: 3.days.ago)
    user_session = login(user)
    using_session(user_session) do
      visit "request/#{info_request.url_title}/track"
    end

    other_user = FactoryBot.create(:user)
    other_user_session = login(other_user)
    using_session(other_user_session) do
      visit "annotate/request/#{info_request.url_title}"
      fill_in "comment[body]", with: 'test comment'
      click_button 'Preview your annotation'
      click_button 'Post annotation'
    end

    destroy_and_rebuild_xapian_index

    TrackMailer.alert_tracks

    expect(deliveries.size).to eq(1)
    mail = deliveries.first
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

    # Check that there's a way to unsubscribe
    target =
      show_user_path(url_name: user.url_name, anchor: 'email_subscriptions')
    subscription_preferences_link = signin_path(r: target)
    expect(mail.body).to include(subscription_preferences_link)

    # Check nothing more is delivered if we try again
    expect { TrackMailer.alert_tracks }.to_not change { deliveries.size }
  end

  it "should send localised alerts" do
    info_request = FactoryBot.create(:info_request)
    user = FactoryBot.create(:user, last_daily_track_email: 3.days.ago)
    user_session = login(user)
    using_session(user_session) do
      visit "/es"
      visit "/request/#{info_request.url_title}/track"
    end

    other_user = FactoryBot.create(:user)
    other_user_session = login(other_user)
    using_session(other_user_session) do
      visit "/en"
      visit "/request/#{info_request.url_title}/annotate"
      fill_in "comment[body]", with: 'test comment'
      click_button 'Preview your annotation'
      click_button 'Post annotation'
    end

    destroy_and_rebuild_xapian_index

    TrackMailer.alert_tracks
    expect(deliveries.size).to eq(1)
    mail = deliveries.first
    expect(mail.body).to include('el equipo de ')
  end
end
