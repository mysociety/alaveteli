require 'spec_helper'

RSpec.describe Statistics::General do
  let(:statistics) { described_class.new }

  before do
    # Clean up fixtures
    InfoRequest.find_each(&:destroy)
    Comment.find_each(&:destroy)
    PublicBody.find_each(&:destroy)
    TrackThing.find_each(&:destroy)
    User.find_each(&:destroy)

    # Create some constant God models for other factories
    user = FactoryBot.create(:user)
    body = FactoryBot.create(:public_body)
    banned_user = FactoryBot.create(:user, ban_text: 'banned')
    info_request = FactoryBot.create(:info_request,
                                     user: user,
                                     public_body: body)

    default_args = { info_request: info_request,
                     public_body: body,
                     user: user }

    # Create the other data we're checking
    FactoryBot.create(:embargoed_request, user: user, public_body: body)
    FactoryBot.create(:info_request, user: user,
                                     public_body: body,
                                     prominence: 'hidden')
    FactoryBot.create(:user, email_confirmed: false)
    FactoryBot.create(:visible_comment,
                      default_args.dup.slice!(:public_body))
    FactoryBot.create(:hidden_comment,
                      default_args.dup.slice!(:public_body))
    FactoryBot.create(:search_track, tracking_user: user)
    FactoryBot.create(:widget_vote,
                      default_args.dup.slice!(:user, :public_body))
    FactoryBot.create(:internal_review_request,
                      default_args.dup.slice!(:user, :public_body))
    FactoryBot.create(:internal_review_request,
                      info_request: info_request, prominence: 'hidden')
    FactoryBot.create(:add_body_request,
                      default_args.dup.slice!(:info_request))
    event = FactoryBot.create(:info_request_event,
                              default_args.dup.slice!(:user, :public_body))
    FactoryBot.create(:request_classification, user: user,
                                               info_request_event: event)
    FactoryBot.create(:citation, user: user, citable: info_request)

    allow(statistics).to receive(:alaveteli_git_commit).and_return('SHA')
  end

  let(:expected) do
    { alaveteli_git_commit: 'SHA',
      alaveteli_version: ALAVETELI_VERSION,
      ruby_version: RUBY_VERSION,
      visible_public_body_count: 1,
      visible_request_count: 1,
      private_request_count: 1,
      confirmed_user_count: 1,
      visible_comment_count: 1,
      track_thing_count: 1,
      widget_vote_count: 1,
      public_body_change_request_count: 1,
      request_classification_count: 1,
      visible_followup_message_count: 1,
      citation_count: 1 }
  end

  describe '#to_h' do
    subject { statistics.to_h }
    it { is_expected.to eq(expected) }
  end

  describe '#to_json' do
    context 'with no arguments' do
      subject { statistics.to_json }
      it { is_expected.to eq(expected.to_json) }
    end

    context 'with arguments' do
      subject { statistics.to_json(args) }
      let(:args) { { not: 'used' } }
      it { is_expected.to eq(expected.to_json) }
    end
  end
end
