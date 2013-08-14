require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'when making a zipfile available' do

    def inspect_zip_download(session, info_request)
        session.get_via_redirect "request/#{info_request.url_title}/download"
        session.response.should be_success
        Tempfile.open('download') do |f|
            f.binmode
            f.write(session.response.body)
            f.flush
            Zip::ZipFile::open(f) do |zip|
               yield zip
            end
        end
    end

    def sleep_and_receive_mail(name, info_request)
        # The path of the zip file is based on the hash of the timestamp of the last request
        # in the thread, so we wait for a second to make sure this one will have a different
        # timestamp than the previous.
        sleep 1
        receive_incoming_mail(name, info_request.incoming_email)
    end

    it "should update the contents of the zipfile when the request changes" do

        info_request = FactoryGirl.create(:info_request_with_incoming)
        request_owner = login(info_request.user)
        inspect_zip_download(request_owner, info_request) do |zip|
            zip.count.should == 1 # just the message
            expected = 'This is a plain-text version of the Freedom of Information request "Example Title"'
            zip.read('correspondence.txt').should match expected
        end

        sleep_and_receive_mail('incoming-request-two-same-name.email', info_request)

        inspect_zip_download(request_owner, info_request) do |zip|
            zip.count.should == 3 # the message plus two "hello-world.txt" files
            zip.read('2_hello world.txt').should match('Second hello')
            zip.read('3_hello world.txt').should match('First hello')
        end

        sleep_and_receive_mail('incoming-request-attachment-unknown-extension.email', info_request)

        inspect_zip_download(request_owner, info_request) do |zip|
            zip.count.should == 4  # the message plus two "hello-world.txt" files, and the new attachment
            zip.read('2_hello.qwglhm').should match('This is an unusual')
        end
    end


    it 'should successfully make a zipfile for an external request' do
        info_request = info_requests(:external_request)
        get_via_redirect "request/#{info_request.url_title}/download"
        response.should be_success
    end

end
