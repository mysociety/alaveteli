require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ContactMailer, "when sending mail with a SafeBuffer name param (as when a suspended user
                         sends a message)" do
    before do

    end

    it 'should set a "from" address correctly' do
        mail = ContactMailer.create_to_admin_message('test (account suspended)'.html_safe,
                                                     'test@example.com',
                                                     'Test subject',
                                                     'Test message',
                                                     mock_model(User, :url_name => 'test_user'),
                                                     mock_model(InfoRequest, :url_title => 'test_request'),
                                                     mock_model(PublicBody, :url_name => 'test_public_body'))
        mail.from.should_not be_nil
    end

end


