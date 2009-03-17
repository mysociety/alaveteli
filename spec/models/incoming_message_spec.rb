require File.dirname(__FILE__) + '/../spec_helper'

describe IncomingMessage, " when dealing with incoming mail" do
    fixtures :incoming_messages, :raw_emails

    before do
        @im = incoming_messages(:useless_incoming_message)
    end

    it "should return the mail Date header date for sent at" do
        @im.sent_at.should == @im.mail.date
    end

    it "should be able to parse emails with quoted commas in" do
        em = "\"Clare College, Cambridge\" <test@test.test>"
        TMail::Address.parse(em)
    end

end

describe IncomingMessage, " display attachments" do

    it "should not show slashes in filenames" do
        foi_attachment = FOIAttachment.new()
        # http://www.whatdotheyknow.com/request/post_commercial_manager_librarie#incoming-17233
        foi_attachment.filename = "FOI/09/066 RESPONSE TO FOI REQUEST RECEIVED 21st JANUARY 2009.txt"
        expected_display_filename = foi_attachment.filename.gsub(/\//, "-")
        foi_attachment.display_filename.should == expected_display_filename
    end

    it "should not show slashes in subject generated filenames" do
        foi_attachment = FOIAttachment.new()
        # http://www.whatdotheyknow.com/request/post_commercial_manager_librarie#incoming-17233
        foi_attachment.within_rfc822_subject = "FOI/09/066 RESPONSE TO FOI REQUEST RECEIVED 21st JANUARY 2009"
        foi_attachment.content_type = 'text/plain'
        expected_display_filename = foi_attachment.within_rfc822_subject.gsub(/\//, "-") + ".txt"
        foi_attachment.display_filename.should == expected_display_filename
    end


end


