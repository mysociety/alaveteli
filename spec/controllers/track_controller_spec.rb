# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TrackController do
  let(:mock_cookie) { '0300fd3e1177127cebff' }

  describe 'GET #track_request' do
    let(:info_request) do
      FactoryBot.create(:info_request,
                        :title => 'My request',
                        :url_title => 'myrequest')
    end
    let(:track_thing) do
      FactoryBot.create(:request_update_track,
                        :info_request => info_request,
                        :track_medium => 'email_daily',
                        :track_query => 'example')
    end
    let(:user) { FactoryBot.create(:user, :locale => 'en', :name => 'bob') }

    it 'clears widget votes for the request' do
      allow(AlaveteliConfiguration).to receive(:enable_widgets).and_return(true)
      info_request.widget_votes.create(:cookie => mock_cookie)

      session[:user_id] = user.id
      request.cookies['widget_vote'] = mock_cookie

      get :track_request, params: {
                            :url_title => info_request.url_title,
                            :feed => 'track'
                          }
      expect(info_request.reload.widget_votes).to be_empty
    end

    it "should require login when making new track" do
      get :track_request, params: {
                            :url_title => info_request.url_title,
                            :feed => 'track'
                          }
      expect(response)
        .to redirect_to(signin_path(:token => get_last_post_redirect.token))
    end

    it "should set no-cache headers on the login redirect" do
      get :track_request, params: {
                            :url_title => info_request.url_title,
                            :feed => 'track'
                          }
      if rails_upgrade?
        expect(response.headers["Cache-Control"]).
          to eq('no-cache, no-store')
      else
        expect(response.headers["Cache-Control"]).
          to eq('no-cache, no-store, max-age=0, must-revalidate')
      end
      expect(response.headers['Pragma']).to eq('no-cache')
      expect(response.headers['Expires']).to eq('0')
    end

    it "should save a request track and redirect if you are logged in" do
      session[:user_id] = user.id
      allow(TrackThing).to receive(:create_track_for_request).and_return(track_thing)
      expect(track_thing).to receive(:save).and_call_original
      get :track_request, params: {
                            :url_title => info_request.url_title,
                            :feed => 'track'
                          }
      expect(response).to redirect_to(:controller => 'request',
                                      :action => 'show',
                                      :url_title => info_request.url_title)
    end

    it "should 404 for non-existent requests" do
      session[:user_id] = user.id
      expect {
        get :track_request, params: { :url_title => "hjksfdh_louytu_qqxxx",
                                      :feed => 'track' }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should 404 for embargoed requests" do
      session[:user_id] = user.id
      embargoed_request = FactoryBot.create(:embargoed_request)
      expect {
        get :track_request, params: { :url_title => embargoed_request.url_title,
                                      :feed => 'track' }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when getting feeds' do

      before do
        load_raw_emails_data
        get_fixtures_xapian_index
      end

      it "should get the RSS feed" do

        track_thing = track_things(:track_fancy_dog_request)

        get :track_request, params: {
                              :feed => 'feed',
                              :url_title => track_thing.info_request.url_title
                            }
        expect(response).to render_template('track/atom_feed')
        expect(response.content_type).to eq('application/atom+xml')
        # TODO: should check it is an atom.builder type being rendered,
        # not sure how to
        expect(assigns[:xapian_object].matches_estimated).to eq(3)
        expect(assigns[:xapian_object].results.size).to eq(3)
        expect(assigns[:xapian_object].results[0][:model])
          .to eq(info_request_events(:silly_comment_event))
        expect(assigns[:xapian_object].results[1][:model])
          .to eq(info_request_events(:useless_incoming_message_event))
        expect(assigns[:xapian_object].results[2][:model])
          .to eq(info_request_events(:useless_outgoing_message_event))
      end

      it "should get JSON version of the feed" do
        track_thing = track_things(:track_fancy_dog_request)

        get :track_request, params: {
                              :feed => 'feed',
                              :url_title => track_thing.info_request.url_title,
                              :format => "json"
                            }

        a = JSON.parse(response.body)
        expect(a.class.to_s).to eq('Array')
        expect(a.size).to eq(3)

        expect(a[0]['id'])
          .to eq(info_request_events(:silly_comment_event).id)
        expect(a[1]['id'])
          .to eq(info_request_events(:useless_incoming_message_event).id)
        expect(a[2]['id'])
          .to eq(info_request_events(:useless_outgoing_message_event).id)

        expect(a[0]['info_request']['url_title'])
          .to eq('why_do_you_have_such_a_fancy_dog')
        expect(a[1]['info_request']['url_title'])
          .to eq('why_do_you_have_such_a_fancy_dog')
        expect(a[2]['info_request']['url_title'])
          .to eq('why_do_you_have_such_a_fancy_dog')

        expect(a[0]['public_body']['url_name']).to eq('tgq')
        expect(a[1]['public_body']['url_name']).to eq('tgq')
        expect(a[2]['public_body']['url_name']).to eq('tgq')

        expect(a[0]['user']['url_name']).to eq('bob_smith')
        expect(a[1]['user']['url_name']).to eq('bob_smith')
        expect(a[2]['user']['url_name']).to eq('bob_smith')

        expect(a[0]['event_type']).to eq('comment')
        expect(a[1]['event_type']).to eq('response')
        expect(a[2]['event_type']).to eq('sent')
      end

      it 'should return atom/xml for a feed url without format specified, even if the
            requester prefers json' do
        request.env['HTTP_ACCEPT'] = 'application/json,text/xml'
        track_thing = FactoryBot.create(:request_update_track)
        get :track_request, params: {
                              :feed => 'feed',
                              :url_title => track_thing.info_request.url_title
                            }
        expect(response).to render_template('track/atom_feed')
        expect(response.content_type).to eq('application/atom+xml')
      end
    end

  end

  describe "GET #track_search_query" do
    let(:track_thing) do
      FactoryBot.create(:search_track,
                        :track_medium => 'email_daily',
                        :track_query => 'example')
    end

    let(:user) { FactoryBot.create(:user, :locale => 'en', :name => 'bob') }

    it "should save a search track and redirect to the right place" do
      session[:user_id] = user.id
      allow(TrackThing).to receive(:create_track_for_search_query).and_return(track_thing)
      expect(track_thing).to receive(:save).and_call_original
      get :track_search_query, params: { :query_array => "bob variety:sent",
                                         :feed => 'track' }
      expect(response).to redirect_to(:controller => 'general', :action => 'search',
                                      :combined => ["bob", "requests"])
    end

    it 'sets the flash message partial for a successful track' do
      session[:user_id] = user.id

      get :track_search_query, params: {
                                 :query_array => 'bob variety:sent',
                                 :feed => 'track'
                               }

      expected = {
        :partial => 'track/track_set',
        :locals => {
            :user_receive_email_alerts => true,
            :user_url_name => user.url_name,
            :track_thing_id => TrackThing.last.id } }

      expect(flash[:notice]).to eq(expected)
    end

    it 'sets the flash message partial when the user is already tracking' do
      session[:user_id] = user.id

      existing =
        FactoryBot.create(:search_track,
                          :tracking_user => user,
                          :track_medium => 'email_daily',
                          :track_query => 'bob variety:sent')

      get :track_search_query, params: {
                                 :query_array => 'bob variety:sent',
                                 :feed => 'track'
                               }

      expected = {
        :partial => 'track/already_tracking',
        :locals => { :track_thing_id => existing.id }
      }

      expect(flash[:notice]).to eq(expected)
    end

    it "should redirect with an error message if the query is too long" do
      long_track = TrackThing.new(:track_type => 'search_query',
                                  :track_query => "lorem ipsum " * 42)
      session[:user_id] = user.id
      allow(TrackThing).to receive(:create_track_for_search_query).and_return(long_track)
      get :track_search_query, params: {
                                 :query_array => "bob variety:sent",
                                 :feed => 'track'
                               }
      expect(flash[:error]).to match('too long')
      expect(response).to redirect_to(:controller => 'general', :action => 'search',
                                      :combined => ["bob", "requests"])
    end
  end

  describe "GET #track_public_body" do
    let(:public_body) { FactoryBot.create(:public_body) }
    let(:user) { FactoryBot.create(:user, :locale => 'en', :name => 'bob') }

    before do
      # these tests depend on the xapian index existing, although
      # not on its specific contents.
      load_raw_emails_data
      get_fixtures_xapian_index
    end

    it "should save a search track and redirect to the right place" do
      session[:user_id] = user.id
      track_thing = TrackThing.new(:track_type => 'public_body_updates',
                                   :public_body => public_body)
      allow(TrackThing).to receive(:create_track_for_public_body).and_return(track_thing)
      expect(track_thing).to receive(:save).and_call_original
      get :track_public_body, params: {
                                :url_name => public_body.url_name,
                                :feed => 'track',
                                :event_type => 'sent'
                              }
      expect(response).to redirect_to("/body/#{public_body.url_name}")
    end

    it "should redirect with an error message if the query is too long" do
      session[:user_id] = user.id
      long_track = TrackThing.new(:track_type => 'public_body_updates',
                                  :public_body => public_body,
                                  :track_query => "lorem ipsum " * 42)
      allow(TrackThing).to receive(:create_track_for_public_body).and_return(long_track)
      get :track_public_body, params: {
                                :url_name => public_body.url_name,
                                :feed => 'track',
                                :event_type => 'sent'
                              }
      expect(flash[:error]).to match('too long')
      expect(response).to redirect_to("/body/#{public_body.url_name}")
    end

    it "should work" do
      get :track_public_body, params: {
                                :feed => 'feed',
                                :url_name => public_body.url_name
                              }
      expect(response).to be_successful
      expect(response).to render_template('track/atom_feed')
      tt = assigns[:track_thing]
      expect(tt.public_body).to eq(public_body)
      expect(tt.track_type).to eq('public_body_updates')
      expect(tt.track_query).to eq("requested_from:" + public_body.url_name)
    end

    it "should filter by event type" do
      get :track_public_body, params: {
                                :feed => 'feed',
                                :url_name => public_body.url_name,
                                :event_type => 'sent'
                              }
      expect(response).to be_successful
      expect(response).to render_template('track/atom_feed')
      tt = assigns[:track_thing]
      expect(tt.public_body).to eq(public_body)
      expect(tt.track_type).to eq('public_body_updates')
      expect(tt.track_query)
        .to eq("requested_from:#{public_body.url_name} variety:sent")
    end

  end

  describe "GET #track_user" do
    let(:target_user) { FactoryBot.create(:user) }
    let(:user) { FactoryBot.create(:user) }

    it "should save a user track and redirect to the right place" do
      session[:user_id] = user.id
      track_thing = TrackThing.new(:track_type => 'user_updates',
                                   :tracked_user => target_user,
                                   :track_query => "requested_by:#{target_user.url_name}")
      allow(TrackThing).to receive(:create_track_for_user).and_return(track_thing)
      expect(track_thing).to receive(:save).and_call_original
      get :track_user, params: { :url_name => target_user.url_name,
                                 :feed => 'track' }
      expect(response).to redirect_to("/user/#{target_user.url_name}")
    end

    it "should redirect with an error message if the query is too long" do
      session[:user_id] = user.id
      long_track = TrackThing.new(:track_type => 'user_updates',
                                  :tracked_user => target_user,
                                  :track_query => "lorem ipsum " * 42)
      allow(TrackThing).to receive(:create_track_for_user).and_return(long_track)
      get :track_user, params: { :url_name => target_user.url_name,
                                 :feed => 'track' }
      expect(flash[:error]).to match('too long')
      expect(response).to redirect_to("/user/#{target_user.url_name}")
    end

    it "should return NotFound for a non-existent user" do
      expect {
        get :track_user, params: { :feed => 'feed',
                                   :url_name => "there_is_no_such_user" }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

  end

  describe "GET #track_list" do
    let(:user) { FactoryBot.create(:user) }

    it "should save a list track and redirect to the right place" do
      session[:user_id] = user.id
      track_thing = TrackThing.new(:track_type => 'all_new_requests',
                                   :track_query => "variety:sent")
      allow(TrackThing).to receive(:create_track_for_all_new_requests).
        and_return(track_thing)
      expect(track_thing).to receive(:save).and_call_original
      get :track_list, params: { :view => 'recent', :feed => 'track' }
      expect(response).to redirect_to("/list?view=recent")
    end

    it "should redirect with an error message if the query is too long" do
      session[:user_id] = user.id
      long_track = TrackThing.new(:track_type => 'all_new_requests',
                                  :track_query => "lorem ipsum " * 42)
      allow(TrackThing).to receive(:create_track_for_all_new_requests).
        and_return(long_track)
      get :track_list, params: { :view => 'recent', :feed => 'track' }
      expect(flash[:error]).to match('too long')
      expect(response).to redirect_to("/list?view=recent")
    end
  end

  describe "PUT #update" do
    let(:track_thing) { FactoryBot.create(:search_track) }

    before do
      session[:user_id] = track_thing.tracking_user.id
    end

    it 'destroys the track thing' do
      put :update, params: {
                     track_id: track_thing.id,
                     track_medium: 'delete',
                     r: 'http://example.com'
                   }
      expect(TrackThing.find_by(id: track_thing.id)).to eq(nil)
    end

    it 'also responds to GET for backwards compatability' do
      get :update, params: {
                     track_id: track_thing.id,
                     track_medium: 'delete',
                     r: 'http://example.com'
                   }
      expect(TrackThing.find_by(id: track_thing.id)).to eq(nil)
    end

    it 'redirects to a URL on the site' do
      put :update, params: {
                     track_id: track_thing.id,
                     track_medium: 'delete',
                     r: '/'
                   }
      expect(response).to redirect_to('/')
    end

    it 'does not redirect to a URL on another site' do
      put :update, params: {
                     track_id: track_thing.id,
                     track_medium: 'delete',
                     r: 'http://example.com/'
                   }
      expect(response).to redirect_to('/')
    end

    it 'raises an error with an invalid track_medium param' do
      msg = 'Given track_medium not handled: invalid123'
      expect {
        put :update, params: {
                       track_id: track_thing.id,
                       track_medium: 'invalid123',
                       r: 'http://example.com/'
                     }
      }.to raise_error(RuntimeError, msg)
    end

    it 'raises an error with no track_medium param' do
      msg = 'No track_medium supplied'
      expect {
        put :update, params: {
                       track_id: track_thing.id,
                       r: 'http://example.com/'
                     }
      }.to raise_error(RuntimeError, msg)
    end

  end

  describe 'POST #delete_all_type' do

    let(:track_thing) { FactoryBot.create(:search_track) }

    context 'when the user passed in the params is not logged in' do

      it 'redirects to the signin page' do
        post :delete_all_type, params: {
                                 :user => track_thing.tracking_user.id,
                                 :track_type => 'search_query'
                               }
        expect(response).
          to redirect_to(signin_path(:token => get_last_post_redirect.token))
      end

    end

    context 'when the user passed in the params is logged in' do

      it 'deletes all tracks for the user of the type passed in the params' do
        post :delete_all_type, params: {
                                 :user => track_thing.tracking_user.id,
                                 :track_type => 'search_query',
                                 :r => '/'
                               },
                               session: {
                                 :user_id => track_thing.tracking_user.id
                               }
        expect(TrackThing.where(:id => track_thing.id)).to be_empty
      end

      it 'redirects to the redirect path in the param passed' do
        post :delete_all_type, params: {
                                 :user => track_thing.tracking_user.id,
                                 :track_type => 'search_query',
                                 :r => '/'
                               },
                               session: {
                                 :user_id => track_thing.tracking_user.id
                               }
        expect(response).to redirect_to('/')
      end

      it 'shows a message telling the user what has happened' do
        post :delete_all_type, params: {
                                 :user => track_thing.tracking_user.id,
                                 :track_type => 'search_query',
                                 :r => '/'
                               },
                               session: {
                                 :user_id => track_thing.tracking_user.id
                               }
        expect(flash[:notice]).to eq("You will no longer be emailed updates for those alerts")
      end

    end

  end
end
