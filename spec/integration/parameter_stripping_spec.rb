# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When handling bad requests" do

    if RUBY_VERSION == '1.9.3'

        it 'should return a 404 for GET requests to a malformed request URL' do
            get 'request/228%85'
            response.status.should == 404
        end

        it 'should redirect a bad UTF-8 POST to a malformed attachment URL' do
            info_request = FactoryGirl.create(:info_request_with_incoming_attachments)
            incoming_message = info_request.incoming_messages.first
            data = { :excerpt => "something\xA3\xA1" }
            post "/en/request/#{info_request.id}/response/#{incoming_message.id}/attach/2/interesting.pdf/trackback", data
            response.status.should == 303
            response.should redirect_to "/en/request/#{info_request.url_title}#incoming-#{incoming_message.id}"
        end

    end

end
