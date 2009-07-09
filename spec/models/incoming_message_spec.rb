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


describe IncomingMessage, "when getting the attachment text" do 

  it "should not raise an error if the expansion of a zip file raises an error" do 
    mock_entry = mock('ZipFile entry', :file? => true)
    mock_entry.stub!(:get_input_stream).and_raise("invalid distance too far back")
    Zip::ZipFile.stub!(:open).and_return([mock_entry])
    IncomingMessage.get_attachment_text_internal_one_file('application/zip', "some string")
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

describe IncomingMessage, " folding quoted parts of emails" do

    it "cope with [ in user names properly" do
            @user = mock_model(User)
            @user.stub!(:name).and_return("Sir [ Bobble")
            @info_request = mock_model(InfoRequest)
            @info_request.stub!(:user).and_return(@user)

            @incoming_message = IncomingMessage.new()
            @incoming_message.info_request = @info_request

            # this gives a warning if [ is in the name
            text = @incoming_message.remove_lotus_quoting("Sir [ Bobble \nSent by: \n")
            text.should == "\n\nFOLDED_QUOTED_SECTION"
    end

end

describe IncomingMessage, " checking validity to reply to" do
    def test_email(email, result)
        @address = mock(TMail::Address)
        @address.stub!(:spec).and_return(email)
        @mail = mock(TMail::Mail)
        @mail.stub!(:from_addrs).and_return( [ @address ] )
        @incoming_message = IncomingMessage.new()
        @incoming_message.stub!(:mail).and_return(@mail)

        @incoming_message.valid_to_reply_to?.should == result
    end

    it "says a valid email is fine" do
        test_email("team@mysociety.org", true)
    end

    it "says postmaster email is bad" do
        test_email("postmaster@mysociety.org", false)
    end

    it "says Mailer-Daemon email is bad" do
        test_email("Mailer-Daemon@mysociety.org", false)
    end

    it "says case mangled MaIler-DaemOn email is bad" do
        test_email("MaIler-DaemOn@mysociety.org", false)
    end

    it "says Auto_Reply email is bad" do
        test_email("Auto_Reply@mysociety.org", false)
    end

    it "says DoNotReply email is bad" do
        test_email("DoNotReply@tube.tfl.gov.uk", false)
    end





end


