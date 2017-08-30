# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "alaveteli_pro/info_requests/dashboard/_projects.html.erb" do
  let(:pro_user) { FactoryGirl.create(:pro_user) }
  let(:phase_counts) do
    {
      "overdue" => 1,
      "draft" => 2,
      "not_drafts" => 8,
      "awaiting_response" => 2,
      "very_overdue" => 1,
      "response_received" => 1,
      "clarification_needed" => 1,
      "complete" => 1,
      "other" => 1
    }.with_indifferent_access
  end

  before do
    TestAfterCommit.with_commits(true) do
      FactoryGirl.create(:info_request, user: pro_user)
      FactoryGirl.create(:waiting_clarification_info_request, user: pro_user)
      FactoryGirl.create(:successful_request, user: pro_user)
      FactoryGirl.create(:error_message_request, user: pro_user)
      FactoryGirl.create(:awaiting_description, user: pro_user)
      FactoryGirl.create(:overdue_request, user: pro_user)
      FactoryGirl.create(:very_overdue_request, user: pro_user)

      FactoryGirl.create(:draft_info_request, user: pro_user)

      public_bodies = FactoryGirl.create_list(:public_body, 10)
      FactoryGirl.create(:info_request_batch, user: pro_user,
                                              public_bodies: public_bodies)
      FactoryGirl.create(:draft_info_request_batch,
                         user: pro_user,
                         public_bodies: public_bodies)
    end
  end

  def render_view
    assign :user, pro_user
    assign :phase_counts, phase_counts
    render partial: 'alaveteli_pro/dashboard/projects'
  end

  def render_empty_view
    # Create a different user so that they have no requests
    assign :user, FactoryGirl.create(:pro_user)
    assign :phase_counts, { "not_drafts" => 0 }.with_indifferent_access
    render partial: 'alaveteli_pro/dashboard/projects'
  end

  describe "All requests link" do
    context "when there are requests" do
      it "Has an 'All requests' link" do
        render_view
        expect(rendered).to have_link("All requests 8", href: alaveteli_pro_info_requests_path)
      end
    end

    context "when there are no requests" do
      it "Has an 'All requests' link" do
        render_empty_view
        expect(rendered).to have_link("All requests 0", href: alaveteli_pro_info_requests_path)
      end
    end
  end

  describe "Request phases links" do
    context "when there are requests" do
      it "Has a link for each request phase" do
        render_view
        InfoRequest::State.phases.each do |phase|
          expected_path = alaveteli_pro_info_requests_path(
              'alaveteli_pro_request_filter[filter]' => phase[:scope]
            )
          # Awaiting response includes the batch request too
          expected_count = phase[:scope] == :awaiting_response ? 2 : 1
          expected_text = "#{phase[:capital_label]} #{expected_count}"
          expect(rendered).to have_link(expected_text, href: expected_path)
        end
      end
    end

    context "when there are no requests" do
      it "Has a label for each request phase" do
        render_empty_view
        InfoRequest::State.phases.each do |phase|
          expected_path = alaveteli_pro_info_requests_path(
              'alaveteli_pro_request_filter[filter]' => phase[:scope]
            )
          expected_text = "#{phase[:capital_label]} 0"
          expect(rendered).to have_content(expected_text)
          expect(rendered).not_to have_link(expected_text, href: expected_path)
        end
      end
    end
  end

  describe "Draft request link" do
    context "when there are requests" do
      it "Has a link for draft requests" do
        render_view
        expected_path = alaveteli_pro_info_requests_path(
            'alaveteli_pro_request_filter[filter]' => 'draft'
          )
        expect(rendered).to have_link("Drafts 2", href: expected_path)
      end
    end

    context "when there are no requests" do
      it "Has a label for draft requests" do
        render_empty_view
        expected_path = alaveteli_pro_info_requests_path(
            'alaveteli_pro_request_filter[filter]' => 'draft'
          )
        expect(rendered).to have_content("Drafts 0")
        expect(rendered).not_to have_link("Drafts 0", href: expected_path)
      end
    end
  end
end
