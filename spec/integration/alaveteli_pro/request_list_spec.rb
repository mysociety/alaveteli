# -*- encoding : utf-8 -*-
require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/../alaveteli_dsl')

describe "pro request list" do
  let(:pro_user) { FactoryGirl.create(:pro_user) }
  let!(:pro_user_session) { login(pro_user) }
  let!(:info_requests) do
    requests = []
    TestAfterCommit.with_commits(true) do
      requests = FactoryGirl.create_list(:info_request, 25, user: pro_user)
    end
    requests
  end
  let(:public_bodies) do
    FactoryGirl.create_list(:public_body, 10)
  end
  let!(:batch_requests) do
    requests = []
    TestAfterCommit.with_commits(true) do
      requests = FactoryGirl.create_list(
        :info_request_batch,
        5,
        user: pro_user,
        public_bodies: public_bodies)
    end
  end

  before do
    # Send 4 out of 5 of the batch requests
    TestAfterCommit.with_commits(true) do
      batch_requests[0..3].each do |batch|
        batch.create_batch!
        batch.reload
      end
    end
  end

  it "shows requests that have been made" do
    using_pro_session(pro_user_session) do
      visit(alaveteli_pro_info_requests_path)
      request = info_requests.last
      expect(page).to have_css("#info-request-#{request.id}")

      within("#info-request-#{request.id}") do
        request_path = show_request_path(url_title: request.url_title)
        expect(page).to have_link(request.title, href: request_path)
        expect(page).to have_content(request.created_at.strftime('%d-%m-%Y'))
        expect(page).to have_content(request.updated_at.strftime('%d-%m-%Y'))
        expect(page).to have_content(request.public_body.name)
      end
    end
  end

  it "shows batch requests alongside other requests" do
    using_pro_session(pro_user_session) do
      visit(alaveteli_pro_info_requests_path)
      batch = batch_requests.first

      expect(batch.info_requests.first.state.phase).to eq(:awaiting_response)
      expect(batch.request_summary.request_summary_categories).to eq([AlaveteliPro::RequestSummaryCategory.awaiting_response])
      expect(page).to have_css("#info-request-batch-#{batch.id}")

      within("#info-request-batch-#{batch.id}") do
        expect(page).to have_field(batch.title)

        expected_public_bodies = "#{batch.public_bodies.first.name} " \
                                 "and #{batch.public_bodies.second.name}"
        expected_description = "10 recipients, including #{expected_public_bodies}"
        expect(page).to have_content(expected_description)

        expect(page).to have_content(batch.created_at.strftime('%d-%m-%Y'))
        expect(page).to have_content(batch.updated_at.strftime('%d-%m-%Y'))

        expected_sent_at = I18n.l(batch.sent_at, format: '%d-%m-%Y - %H:%M %p')
        expect(page).to have_content(expected_sent_at)

        expect(page).to have_content("10 In progress")

        # Should not show individual requests until we click the link to
        # expand them
        batch.info_requests.each do |request|
          expect(page).not_to have_css("info-request-#{request.id}")
        end

        # The batch title is the label for the houdini checkbox that shows the
        # bodies
        check batch.title

        batch.info_requests.each do |request|
          expect(page).to have_css("#info-request-#{request.id}")
          within("#info-request-#{request.id}") do
            request_path = show_request_path(request.url_title)
            expect(page).to have_link(request.public_body.name, href: request_path)
            expect(page).to have_content("Awaiting response")
          end
        end
      end
    end
  end

  it "shows batch requests that haven't been sent yet" do
    using_pro_session(pro_user_session) do
      visit(alaveteli_pro_info_requests_path)
      batch = batch_requests.last
      expect(page).to have_css("#info-request-batch-#{batch.id}")

      within("#info-request-batch-#{batch.id}") do
        expect(page).to have_field(batch.title)

        expected_public_bodies = "#{batch.public_bodies.first.name} " \
                                 "and #{batch.public_bodies.second.name}"
        expected_description = "10 recipients, including #{expected_public_bodies}"
        expect(page).to have_content(expected_description)

        expect(page).to have_content(batch.created_at.strftime('%d-%m-%Y'))
        expect(page).to have_content(batch.updated_at.strftime('%d-%m-%Y'))
        expect(page).to have_content("Pending")
        expect(page).to have_content("10 Pending")

        # Should not show bodies until we click the link
        batch.info_requests.each do |request|
          expect(page).not_to have_css("info-request-#{request.id}")
        end

        # The batch title is the label for the houdini checkbox that shows the
        # bodies
        check batch.title

        batch.info_requests.each do |request|
          expect(page).to have_css("info-request-#{request.id}")
          within("info-request-#{request.id}") do
            request_path = show_request_path(request.id)
            expect(page).to have_content(request.public_body.name)
            expect(page).to have_content("Awaiting response")
          end
        end
      end
    end
  end

  describe "showing draft requests" do
    let!(:draft_request) do
      draft = nil
      TestAfterCommit.with_commits(true) do
        draft = FactoryGirl.create(:draft_info_request, user: pro_user)
      end
      draft
    end
    let!(:draft_batch_request) do
      draft = nil
      TestAfterCommit.with_commits(true) do
        draft = FactoryGirl.create(
          :draft_info_request_batch,
          user: pro_user,
          public_bodies: public_bodies
        )
      end
      draft
    end

    it "shows draft requests" do
      using_pro_session(pro_user_session) do
        visit(alaveteli_pro_info_requests_path)
        click_link "Drafts"

        expect(page).to have_css("#draft-info-request-#{draft_request.id}")
      end
    end

    it "shows draft batch requests" do
      using_pro_session(pro_user_session) do
        visit(alaveteli_pro_info_requests_path)
        click_link "Drafts"

        expect(page).to have_css("#draft-info-request-batch-#{draft_batch_request.id}")
      end
    end
  end
end
