# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminRawEmailController do

  describe 'GET show' do

    before do
      @raw_email = FactoryGirl.create(:incoming_message).raw_email
    end

    describe 'html version' do

      it 'renders the show template' do
        get :show, :id => @raw_email.id
      end

      context 'when showing a message with a "From" address in the holding pen' do

        before do
          @public_body = FactoryGirl.create(:public_body,
                                            :request_email => 'body@example.uk')
          @info_request = FactoryGirl.create(:info_request)
          raw_email_data = <<-EOF.strip_heredoc
          From: bob@example.uk
          To: #{@info_request.incoming_email}
          Subject: Basic Email
          Hello, World
          EOF
          @incoming_message = FactoryGirl.create(
            :plain_incoming_message,
            :info_request => InfoRequest.holding_pen_request,
          )
          @incoming_message.raw_email.data = raw_email_data
          @incoming_message.raw_email.save!
          @info_request_event = FactoryGirl.create(
            :info_request_event,
            :event_type => 'response',
            :info_request => InfoRequest.holding_pen_request,
            :incoming_message => @incoming_message,
            :params => {:rejected_reason => 'Too dull'}
          )
        end

        it 'assigns public bodies that match the "From" domain' do
          get :show, :id => @incoming_message.raw_email.id
          expect(assigns[:public_bodies]).to eq [@public_body]
        end

        it 'assigns info requests based on the hash' do
          get :show, :id => @incoming_message.raw_email.id
          expect(assigns[:info_requests]).to eq [@info_request]
        end

        it 'assigns a reason why the message is in the holding pen' do
          get :show, :id => @incoming_message.raw_email.id
          expect(assigns[:rejected_reason]).to eq 'Too dull'
        end

        it 'assigns a default reason if no reason is given' do
          @info_request_event.params_yaml = {}.to_yaml
          @info_request_event.save!
          get :show, :id => @incoming_message.raw_email.id
          expect(assigns[:rejected_reason]).to eq 'unknown reason'
        end

      end

    end

    describe 'text version' do

      it 'sends the email as an RFC-822 attachment' do
        get :show, :id => @raw_email.id, :format => 'txt'
        expect(response.content_type).to eq('message/rfc822')
        expect(response.body).to eq(@raw_email.data)
      end
    end

  end

end
