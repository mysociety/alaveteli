# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "followups/_followup.html.erb" do

  let(:info_request) { FactoryBot.create(:info_request) }

  before do
    assign :info_request, info_request
    assign :internal_review, false
    assign :outgoing_message, OutgoingMessage.new(info_request: info_request)
    assign :is_owning_user, true
  end

  it "renders the normal title partial when the request is not embargoed" do
    render partial: "followups/followup", locals: { incoming_message: nil }

    expect(view).to render_template(partial: "followups/_form_title")
  end

  it "renders the pro title partial when the request is embargoed" do
    info_request = FactoryBot.create(:embargoed_request)
    assign :info_request, info_request
    assign :internal_review, false
    assign :outgoing_message, OutgoingMessage.new(info_request: info_request)
    assign :is_owning_user, true

    render partial: "followups/followup", locals: { incoming_message: nil }

    expect(view).to render_template(partial: "alaveteli_pro/followups/_embargoed_form_title")
  end

  describe 'the request is overdue' do

    context 'the authority is subject to FOI law' do

      it 'tells the user the authority should have responded by law' do
        travel_to(info_request.date_response_required_by + 2.days) do
          render partial: "followups/followup",
                 locals: { incoming_message: nil }
          expect(rendered).
            to have_content 'You can say that, by law, the authority should ' \
                            'normally have responded'
        end
      end

    end

    context 'the authority is not subject to FOI law' do

      it 'tells the user the authority should have responded by law' do
        info_request.public_body.add_tag_if_not_already_present('foi_no')
        travel_to(info_request.date_response_required_by + 2.days) do
          render partial: "followups/followup",
                 locals: { incoming_message: nil }
          expect(rendered).
            to_not have_content 'You can say that, by law, the authority ' \
                                'should normally have responded'
        end
      end

    end

  end

  describe 'the request is very overdue' do

    context 'the authority is subject to FOI law' do

      it 'tells the user the authority should have responded by law' do
        travel_to(info_request.date_very_overdue_after + 2.days) do
          render partial: "followups/followup",
                 locals: { incoming_message: nil }
          expect(rendered).
            to have_content 'You can say that, by law, under all ' \
                            'circumstances, the authority should have ' \
                            'responded by now'
        end
      end

    end

    context 'the authority is not subject to FOI law' do

      it 'tells the user the authority should have responded by law' do
        info_request.public_body.add_tag_if_not_already_present('foi_no')
        travel_to(info_request.date_very_overdue_after + 2.days) do
          render partial: "followups/followup",
                 locals: { incoming_message: nil }
          expect(rendered).
            to_not have_content 'You can say that, by law, under all ' \
                                'circumstances, the authority should have ' \
                                'responded by now'
        end
      end

    end

  end

  describe 'displaying followup contact options' do

    context 'without an incoming message' do

      it 'does not show the "other options" panel' do
        render partial: "followups/followup", locals: { incoming_message: nil }
        expect(rendered).to_not have_content 'You can also write to'
      end

    end

    context 'with an incoming message' do

      let(:incoming) do
        FactoryBot.create(:plain_incoming_message, info_request: info_request)
      end

      it 'shows the "other options" panel if the incoming message is not from the main contact address' do
        render partial: "followups/followup",
               locals: { incoming_message: incoming }
        expect(rendered).to have_content 'You can also write to'
      end

      it 'does not show the "other options" panel if the incoming message is from the main contact address' do
        info_request.
          public_body.
            update_attribute(:request_email, 'bob@example.com')
        render partial: "followups/followup",
               locals: { incoming_message: incoming }
        expect(rendered).to_not have_content 'You can also write to'
      end

    end

  end

  describe 'the request is closed to new responses' do

    before do
      info_request.update_attribute(:allow_new_responses_from, 'nobody')
    end

    it 'does not render the title partial' do
      render partial: 'followups/followup', locals: { incoming_message: nil }
      expect(rendered).to_not have_css('h2', text: 'Send a public follow up')
    end

    it 'does not render the followup form' do
      render partial: 'followups/followup', locals: { incoming_message: nil }
      expect(rendered).to_not have_css 'form#followup_form'
    end

    it 'renders a message to say new responses have been stopped' do
      render partial: 'followups/followup', locals: { incoming_message: nil }

      expect(rendered).
        to have_content 'Follow ups and new responses to this request have ' \
                        'been stopped to prevent spam.'
    end

  end

end
