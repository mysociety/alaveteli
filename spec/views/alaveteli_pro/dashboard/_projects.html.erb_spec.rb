# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "alaveteli_pro/info_requests/dashboard/_projects.html.erb" do
  let(:pro_user) { FactoryBot.create(:pro_user) }

  before do
    TestAfterCommit.with_commits(true) do
      FactoryBot.create(:info_request, user: pro_user)
      FactoryBot.create(:waiting_clarification_info_request, user: pro_user)
      FactoryBot.create(:successful_request, user: pro_user)
      FactoryBot.create(:error_message_request, user: pro_user)
      FactoryBot.create(:awaiting_description, user: pro_user)
      FactoryBot.create(:overdue_request, user: pro_user)
      FactoryBot.create(:very_overdue_request, user: pro_user)

      FactoryBot.create(:draft_info_request, user: pro_user)

      public_bodies = FactoryBot.create_list(:public_body, 10)
      FactoryBot.create(:info_request_batch, user: pro_user,
                                             public_bodies: public_bodies)
      FactoryBot.create(:draft_info_request_batch,
                        user: pro_user,
                        public_bodies: public_bodies)
    end
  end

  def render_view
    assign :user, pro_user
    render partial: 'alaveteli_pro/dashboard/projects'
  end

  def render_empty_view
    # Create a different user so that they have no requests
    assign :user, FactoryBot.create(:pro_user)
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
          expected_text = /#{phase[:capital_label]}\s*0/
          expect(rendered).to have_content(expected_text)
          expect(rendered).
            not_to have_link(text: expected_text, href: expected_path)
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
        expect(rendered).to have_link(text: /Drafts\s*2/, href: expected_path)
      end
    end

    context "when there are no requests" do
      it "Has a label for draft requests" do
        render_empty_view
        expected_path = alaveteli_pro_info_requests_path(
            'alaveteli_pro_request_filter[filter]' => 'draft'
          )
        expect(rendered).to have_content(/Drafts\s*0/)
        expect(rendered).
          not_to have_link(text: /Drafts\s*0/, href: expected_path)
      end
    end
  end
end
