# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InfoRequestHelper do

  include InfoRequestHelper

  describe '#status_text' do
    let(:info_request) { FactoryGirl.create(:info_request) }

    it 'requires an info_request argument' do
      expect { status_text }.to raise_error(ArgumentError)
    end

    it 'delegates the info_request argument for a valid status' do
      allow(info_request).to receive(:calculate_status).and_return('successful')
      expect(self).to receive(:send).with('status_text_successful', info_request, {})
      status_text(info_request)
    end

    it 'delegates the options for a valid status' do
      allow(info_request).to receive(:calculate_status).and_return('successful')
      opts = {is_owning_user: false}
      expect(self).to receive(:send).with('status_text_successful', info_request, opts)
      status_text(info_request, opts)
    end

    it 'delegates to the custom partial for an unknown status' do
      allow(info_request).to receive(:calculate_status).and_return('unknown')
      opts = {is_owning_user: false}
      expect(self).to receive(:custom_state_description).with(info_request, opts)
      status_text(info_request, opts)
    end

    context 'waiting_response' do

      it 'returns a description' do
        time_travel_to(Date.parse('2014-12-31'))

        body = info_request.public_body
        body_link = %Q(<a href="/body/#{ body.url_name }">#{ body.name }</a>)

        allow(info_request).to receive(:calculate_status).and_return("waiting_response")
        allow(info_request).to receive(:date_response_required_by).and_return(Time.now)

        response_date = '<time datetime="2014-12-31T00:00:00Z" ' \
                        'title="2014-12-31 00:00:00 UTC">' \
                        'December 31, 2014</time>'

        expected = "Currently <strong>waiting for a response</strong> from " \
                   "#{ body_link }, they must respond promptly and " \
                   "normally no later than <strong>#{ response_date }" \
                   "</strong> (<a href=\"/help/requesting#" \
                   "quickly_response\">details</a>)."

        expect(status_text(info_request)).to eq(expected)

        back_to_the_present
      end

    end

    context 'waiting_response_overdue' do

      it 'returns a description' do
        time_travel_to(Date.parse('2014-12-31'))

        body = info_request.public_body
        body_link = %Q(<a href="/body/#{ body.url_name }">#{ body.name }</a>)

        allow(info_request).to receive(:calculate_status).and_return("waiting_response_overdue")
        allow(info_request).to receive(:date_response_required_by).and_return(Time.now)

        response_date = '<time datetime="2014-12-31T00:00:00Z" ' \
                        'title="2014-12-31 00:00:00 UTC">' \
                        'December 31, 2014</time>'

        expected = "Response to this request is <strong>delayed</strong>. " \
                   "By law, #{ body_link } should normally have responded " \
                   "<strong>promptly</strong> and by <strong>" \
                   "#{ response_date }</strong> " \
                   "(<a href=\"/help/requesting#quickly_response\">details</a>)"

        expect(status_text(info_request)).to eq(expected)

        back_to_the_present
      end

    end


    context 'waiting_response_very_overdue' do

      it 'returns a description for an internal request' do
        time_travel_to(Date.parse('2014-12-31'))

        body = info_request.public_body
        body_link = %Q(<a href="/body/#{ body.url_name }">#{ body.name }</a>)

        allow(info_request).to receive(:calculate_status).and_return("waiting_response_very_overdue")
        allow(info_request).to receive(:date_response_required_by).and_return(Time.now)

        response_date = '<time datetime="2014-12-31T00:00:00Z" ' \
                        'title="2014-12-31 00:00:00 UTC">' \
                        'December 31, 2014</time>'

        expected = "Response to this request is <strong>long overdue" \
                   "</strong>. By law, under all circumstances, " \
                   "#{ body_link } should have responded by now " \
                   "(<a href=\"/help/requesting#quickly_response\">details" \
                   "</a>). You can <strong>complain</strong> by " \
                   "<a href=\"/request/#{info_request.id}/followups/new?" \
                   "internal_review=1#followup\">requesting an internal " \
                   "review</a>."

        expect(status_text(info_request)).to eq(expected)

        back_to_the_present
      end

      it 'does not add a followup link for external requests' do
        time_travel_to(Date.parse('2014-12-31'))

        body = info_request.public_body
        body_link = %Q(<a href="/body/#{ body.url_name }">#{ body.name }</a>)

        allow(info_request).to receive(:calculate_status).and_return("waiting_response_very_overdue")
        allow(info_request).to receive(:date_response_required_by).and_return(Time.now)
        allow(info_request).to receive(:is_external?).and_return(true)

        response_date = '<time datetime="2014-12-31T00:00:00Z" ' \
                        'title="2014-12-31 00:00:00 UTC">' \
                        'December 31, 2014</time>'

        expected = "Response to this request is <strong>long overdue" \
                   "</strong>. By law, under all circumstances, " \
                   "#{ body_link } should have responded by now " \
                   "(<a href=\"/help/requesting#quickly_response\">details" \
                   "</a>)."

        expect(status_text(info_request)).to eq(expected)

        back_to_the_present
      end

    end

    context 'not_held' do

      it 'returns a description' do
        body = info_request.public_body
        body_link = %Q(<a href="/body/#{ body.url_name }">#{ body.name }</a>)

        allow(info_request).to receive(:calculate_status).and_return("not_held")

        expected = "#{ body_link } <strong>did not have</strong> the " \
                   "information requested."

        expect(status_text(info_request)).to eq(expected)
      end

    end

    context 'rejected' do

      it 'returns a description' do
        body = info_request.public_body
        body_link = %Q(<a href="/body/#{ body.url_name }">#{ body.name }</a>)

        allow(info_request).to receive(:calculate_status).and_return("rejected")

        expected = "The request was <strong>refused</strong> by #{ body_link }."

        expect(status_text(info_request)).to eq(expected)
      end

    end

    context 'successful' do

      it 'returns a description' do
        expected = 'The request was <strong>successful</strong>.'
        allow(info_request).to receive(:calculate_status).and_return("successful")
        expect(status_text(info_request)).to eq(expected)
      end

    end

    context 'partially_successful' do

      it 'returns a description' do
        expected = 'The request was <strong>partially successful</strong>.'
        allow(info_request).to receive(:calculate_status).and_return("partially_successful")
        expect(status_text(info_request)).to eq(expected)
      end

    end

    context 'waiting_clarification' do

      before do
        allow(info_request).to receive(:calculate_status).and_return("waiting_clarification")
      end

      it 'returns a description for the request owner' do
        body = info_request.public_body

        allow(info_request).to receive(:get_last_public_response).and_return(nil)

        expected = "#{ body.name } is <strong>waiting for your clarification" \
                   "</strong>. Please <a href=\"/request/#{info_request.id}/followups/new" \
                   "#followup\">send a follow up message</a>."

        actual = status_text(info_request, :is_owning_user => true)

        expect(actual).to eq(expected)
      end

      it 'returns a description for internal requests' do
        user = info_request.user

        user_link = "<a href=\"/user/#{user.url_name}\">#{user.name}</a>"
        sign_in_link = '<a href="/profile/sign_in?r=%2Frequest%2Fexample">' \
                       'sign in</a>'

        expected = "The request is <strong>waiting for clarification" \
                   "</strong>. If you are #{ user_link }, please " \
                   "#{ sign_in_link } to send a follow up message."

        actual = status_text(info_request,
                             :is_owning_user => false,
                             :redirect_to => '/request/example')

        expect(actual).to eq(expected)
      end

      it 'does not add a followup link for external requests' do
        allow(info_request).to receive(:is_external?).and_return(true)
        expected = 'The request is <strong>waiting for clarification</strong>.'
        actual = status_text(info_request, :is_owning_user => false)
        expect(actual).to eq(expected)
      end

      it 'requires an is_owning_user option' do
        expect {
          status_text(info_request)
        }.to raise_error(KeyError)
      end

      it 'requires a redirect_to option' do
        expect {
          status_text(info_request, :is_owning_user => false)
        }.to raise_error(KeyError)
      end

    end

    context 'gone_postal' do

      it 'returns a description' do
        allow(info_request).to receive(:calculate_status).and_return("gone_postal")
        expected = 'The authority would like to / has <strong>responded by ' \
                   'post</strong> to this request.'
        expect(status_text(info_request)).to eq(expected)
      end

    end

    context 'internal_review' do

      it 'returns a description' do
        body = info_request.public_body
        allow(info_request).to receive(:calculate_status).and_return("internal_review")
        expected = "Waiting for an <strong>internal review</strong> by " \
                   "<a href=\"/body/#{ body.url_name }\">#{ body.name }</a> " \
                   "of their handling of this request."
        expect(status_text(info_request)).to eq(expected)
      end

    end

    context 'error_message' do

      it 'returns a description' do
        allow(info_request).to receive(:calculate_status).and_return("error_message")
        expected = 'There was a <strong>delivery error</strong> or similar, ' \
                   'which needs fixing by the Alaveteli team.'
        expect(status_text(info_request)).to eq(expected)
      end

    end

    context 'requires_admin' do

      it 'returns a description' do
        allow(info_request).to receive(:calculate_status).and_return("requires_admin")
        expected = 'This request has had an unusual response, and <strong>' \
                   'requires attention</strong> from the Alaveteli team.'
        expect(status_text(info_request)).to eq(expected)
      end

    end

    context 'user_withdrawn' do

      it 'returns a description' do
        allow(info_request).to receive(:calculate_status).and_return("user_withdrawn")
        expected = 'This request has been <strong>withdrawn</strong> by the ' \
                   'person who made it. There may be an explanation in the ' \
                   'correspondence below.'
        expect(status_text(info_request)).to eq(expected)
      end

    end

    context 'attention_requested' do

      it 'returns a description' do
        allow(info_request).to receive(:calculate_status).and_return("attention_requested")
        expected = 'This request has been <strong>reported</strong> as ' \
                   'needing administrator attention (perhaps because it is ' \
                   'vexatious, or a request for personal information)'
        expect(status_text(info_request)).to eq(expected)
      end

    end

    context 'vexatious' do

      it 'returns a description' do
        allow(info_request).to receive(:calculate_status).and_return("vexatious")
        expected = 'This request has been <strong>hidden</strong> from the ' \
                   'site, because an administrator considers it vexatious'
        expect(status_text(info_request)).to eq(expected)
      end

    end

    context 'not_foi' do

      it 'returns a description' do
        allow(info_request).to receive(:calculate_status).and_return("not_foi")
        expected = 'This request has been <strong>hidden</strong> from the ' \
                   'site, because an administrator considers it not to be an ' \
                   'FOI request'
        expect(status_text(info_request)).to eq(expected)
      end

    end

    context 'awaiting_description' do
      before do
        allow(info_request).to receive(:awaiting_description).and_return(true)
      end

      shared_examples_for "when we can't ask the user to update the status" do
        context "when there's one new reponse" do
          it 'asks the user to answer the question' do
            expected = "We're waiting for " \
                       "#{user_link_for_request(info_request)} to read a " \
                       "recent response and update the status."
            expect(message).to eq(expected)
          end
        end

        context "when there's more than one new response" do
          it 'asks the user to answer the question' do
            expected = "We're waiting for " \
                       "#{user_link_for_request(info_request)} to read " \
                       "recent responses and update the status."
            expect(plural_message).to eq(expected)
          end
        end
      end

      context 'owning user' do
        context "when there's one new reponse" do
          it 'asks the user to answer the question' do
            expected = 'Please <strong>answer the question above</strong> so ' \
                       'we know whether the recent response contains useful ' \
                       'information.'
            actual = status_text(info_request,
                                 :new_responses_count => 1,
                                 :is_owning_user => true,
                                 :render_to_file => false,
                                 :old_unclassified => false)
            expect(actual).to eq(expected)
          end
        end

        context "when there's more than one new response" do
          it 'asks the user to answer the question' do
            expected = 'Please <strong>answer the question above</strong> so ' \
                       'we know whether the recent responses contain useful ' \
                       'information.'
            actual = status_text(info_request,
                                 :new_responses_count => 3,
                                 :is_owning_user => true,
                                 :render_to_file => false,
                                 :old_unclassified => true)
            expect(actual).to eq(expected)
          end
        end
      end

      context 'old, unclassified request' do
        context "when there's one new reponse" do
          it 'asks the user to answer the question' do
            expected = "This request has an <strong>unknown status</strong>. " \
                       "We're waiting for someone to read a recent response " \
                       "and update the status accordingly. Perhaps " \
                       "<strong>you</strong> might like to help out by doing " \
                       "that?"
            actual = status_text(info_request,
                                 :new_responses_count => 1,
                                 :is_owning_user => false,
                                 :render_to_file => false,
                                 :old_unclassified => true)
            expect(actual).to eq(expected)
          end
        end

        context "when there's more than one new response" do
          it 'asks the user to answer the question' do
            expected = "This request has an <strong>unknown status</strong>. " \
                       "We're waiting for someone to read recent responses " \
                       "and update the status accordingly. Perhaps " \
                       "<strong>you</strong> might like to help out by doing " \
                       "that?"
            actual = status_text(info_request,
                                 :new_responses_count => 3,
                                 :is_owning_user => false,
                                 :render_to_file => false,
                                 :old_unclassified => true)
            expect(actual).to eq(expected)
          end
        end
      end

      context 'external request' do
        it_behaves_like "when we can't ask the user to update the status" do
          let(:info_request) { FactoryGirl.create(:external_request, awaiting_description: true) }
          let(:message) do
            status_text(info_request,
                        :new_responses_count => 1,
                        :is_owning_user => true,
                        :render_to_file => false,
                        :old_unclassified => false)
          end
          let(:plural_message) do
            status_text(info_request,
                        :new_responses_count => 3,
                        :is_owning_user => true,
                        :render_to_file => false,
                        :old_unclassified => false)
          end
        end
      end

      context 'rendering to a file' do
        it_behaves_like "when we can't ask the user to update the status" do
          let(:message) do
            status_text(info_request,
                        :new_responses_count => 1,
                        :is_owning_user => true,
                        :render_to_file => true,
                        :old_unclassified => false)
          end
          let(:plural_message) do
            status_text(info_request,
                        :new_responses_count => 3,
                        :is_owning_user => true,
                        :render_to_file => true,
                        :old_unclassified => false)
          end
        end
      end

      context 'non-owner viewing a recent request' do
        it_behaves_like "when we can't ask the user to update the status" do
          let(:message) do
            status_text(info_request,
                        :new_responses_count => 1,
                        :is_owning_user => false,
                        :render_to_file => false,
                        :old_unclassified => false)
          end
          let(:plural_message) do
            status_text(info_request,
                        :new_responses_count => 3,
                        :is_owning_user => false,
                        :render_to_file => false,
                        :old_unclassified => false)
          end

        end

      end

    end

  end

end
