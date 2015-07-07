# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminRawEmailController do

    describe :show do

        before do
            @raw_email = FactoryGirl.create(:incoming_message).raw_email
        end

        describe 'html version' do

            it 'renders the show template' do
                get :show, :id => @raw_email.id
            end

        end

        describe 'text version' do

            it 'sends the email as an RFC-822 attachment' do
                get :show, :id => @raw_email.id, :format => 'txt'
                response.content_type.should == 'message/rfc822'
                response.body.should == @raw_email.data
            end
        end

    end

end
