# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'when making a zipfile available' do

  after do
    FileUtils.rm_rf(InfoRequest.download_zip_dir)
  end

  def inspect_zip_download(session, info_request)
    session.get_via_redirect "request/#{info_request.url_title}/download"
    session.response.should be_success
    Tempfile.open('download') do |f|
      f.binmode
      f.write(session.response.body)
      f.flush
      Zip::ZipFile::open(f.path) do |zip|
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

  context 'when an html to pdf converter is supplied' do

    before do
      # We want to test the contents of the pdf, and we don't know whether a particular
      # instance will have a working html_to_pdf tool, so just copy the HTML rendered
      # to the PDF file for the purposes of checking it doesn't contain anything that
      # shouldn't be there.
      AlaveteliConfiguration.stub!(:html_to_pdf_command).and_return('/bin/cp')
    end

    context 'when an incoming message is made "requester_only"' do

      it 'should not include the incoming message or attachments in a download of the entire request
                by a non-request owner but should retain them for owner and admin' do

        # Non-owner can download zip with incoming and attachments
        non_owner = login(FactoryGirl.create(:user))
        info_request = FactoryGirl.create(:info_request_with_incoming_attachments)

        inspect_zip_download(non_owner, info_request) do |zip|
          zip.count.should == 3
          zip.read('correspondence.pdf').should match('hereisthetext')
        end

        # Admin makes the incoming message requester only
        admin = login(FactoryGirl.create(:admin_user))
        post_data = {:incoming_message => {:prominence => 'requester_only',
                                           :prominence_reason => 'boring'}}
        admin.put_via_redirect "/en/admin/incoming_messages/#{info_request.incoming_messages.first.id}", post_data
        admin.response.should be_success

        # Admin retains the requester only things
        inspect_zip_download(admin, info_request) do |zip|
          zip.count.should == 3
          zip.read('correspondence.pdf').should match('hereisthetext')
        end

        # Zip for non owner is now without requester_only things
        inspect_zip_download(non_owner, info_request) do |zip|
          zip.count.should == 1
          correspondence_text = zip.read('correspondence.pdf')
          correspondence_text.should_not match('hereisthetext')
          expected_text = "This message has been hidden.\n    boring"
          correspondence_text.should match(expected_text)
        end

        # Requester retains the requester only things
        owner = login(info_request.user)
        inspect_zip_download(owner, info_request) do |zip|
          zip.count.should == 3
          zip.read('correspondence.pdf').should match('hereisthetext')
        end

      end

    end

    context 'when an outgoing message is made "requester_only"' do

      it 'should not include the outgoing message in a download of the entire request
                by a non-request owner but should retain them for owner and admin' do

        # Non-owner can download zip with outgoing
        non_owner = login(FactoryGirl.create(:user))
        info_request = FactoryGirl.create(:info_request)

        inspect_zip_download(non_owner, info_request) do |zip|
          zip.count.should == 1
          zip.read('correspondence.pdf').should match('Some information please')
        end

        # Admin makes the incoming message requester only
        admin = login(FactoryGirl.create(:admin_user))
        post_data = {:outgoing_message => {:prominence => 'requester_only',
                                           :prominence_reason => 'boring',
                                           :body => 'Some information please'}}
        admin.put_via_redirect "/en/admin/outgoing_messages/#{info_request.outgoing_messages.first.id}", post_data
        admin.response.should be_success

        # Admin retains the requester only things
        inspect_zip_download(admin, info_request) do |zip|
          zip.count.should == 1
          zip.read('correspondence.pdf').should match('Some information please')
        end

        # Zip for non owner is now without requester_only things
        inspect_zip_download(non_owner, info_request) do |zip|
          zip.count.should == 1
          correspondence_text = zip.read('correspondence.pdf')
          correspondence_text.should_not match('Some information please')
          expected_text = "This message has been hidden.\n    boring"
          correspondence_text.should match(expected_text)
        end

        # Requester retains the requester only things
        owner = login(info_request.user)
        inspect_zip_download(owner, info_request) do |zip|
          zip.count.should == 1
          zip.read('correspondence.pdf').should match('Some information please')
        end

      end

    end

  end

  context 'when no html to pdf converter is supplied' do

    before do
      AlaveteliConfiguration.stub!(:html_to_pdf_command).and_return('')
    end

    it "should update the contents of the zipfile when the request changes" do

      info_request = FactoryGirl.create(:info_request_with_incoming,
                                        :title => 'Example Title')
      request_owner = login(info_request.user)
      inspect_zip_download(request_owner, info_request) do |zip|
        zip.count.should == 1 # just the message
        expected = 'This is a plain-text version of the Freedom of Information request "Example Title"'
        zip.read('correspondence.txt').should match expected
      end

      sleep_and_receive_mail('incoming-request-two-same-name.email', info_request)

      inspect_zip_download(request_owner, info_request) do |zip|
        zip.count.should == 3 # the message plus two "hello-world.txt" files
        zip.read('2_2_hello world.txt').should match('Second hello')
        zip.read('2_3_hello world.txt').should match('First hello')
      end

      sleep_and_receive_mail('incoming-request-attachment-unknown-extension.email', info_request)

      inspect_zip_download(request_owner, info_request) do |zip|
        zip.count.should == 4  # the message plus two "hello-world.txt" files, and the new attachment
        zip.read('3_2_hello.qwglhm').should match('This is an unusual')
      end
    end

    context 'when a request is "requester_only"' do

      before do
        @non_owner = login(FactoryGirl.create(:user))
        @info_request = FactoryGirl.create(:info_request_with_incoming,
                                           :prominence => 'requester_only')
        @request_owner = login(@info_request.user)
        @admin = login(FactoryGirl.create(:admin_user))
      end


      it 'should allow a download of the request by the request owner and admin only' do
        # Requester can access the zip
        inspect_zip_download(@request_owner, @info_request) do |zip|
          zip.count.should == 1
          zip.read('correspondence.txt').should match('hereisthetext')
        end
        # Non-owner can't
        @non_owner.get_via_redirect "request/#{@info_request.url_title}/download"
        @non_owner.response.code.should == '403'
        # Admin can
        inspect_zip_download(@admin, @info_request) do |zip|
          zip.count.should == 1
          zip.read('correspondence.txt').should match('hereisthetext')
        end
      end
    end

    context 'when a request is "hidden"' do

      it 'should not allow a download of the request by an admin only' do
        @non_owner = login(FactoryGirl.create(:user))
        @info_request = FactoryGirl.create(:info_request_with_incoming,
                                           :prominence => 'hidden')
        @request_owner = login(@info_request.user)
        @admin = login(FactoryGirl.create(:admin_user))

        # Requester can't access the zip
        @request_owner.get_via_redirect "request/#{@info_request.url_title}/download"
        @request_owner.response.code.should == '403'
        # Non-owner can't
        @non_owner.get_via_redirect "request/#{@info_request.url_title}/download"
        @non_owner.response.code.should == '403'
        # Admin can
        inspect_zip_download(@admin, @info_request) do |zip|
          zip.count.should == 1
          zip.read('correspondence.txt').should match('hereisthetext')
        end
      end

    end

    context 'when an incoming message is made "requester_only"' do

      it 'should not include the incoming message or attachments in a download of the entire request
                by a non-request owner but should retain them for owner and admin' do

        # Non-owner can download zip with outgoing
        non_owner = login(FactoryGirl.create(:user))
        info_request = FactoryGirl.create(:info_request_with_incoming_attachments)

        inspect_zip_download(non_owner, info_request) do |zip|
          zip.count.should == 3
          zip.read('correspondence.txt').should match('hereisthetext')
        end

        # Admin makes the incoming message requester only
        admin = login(FactoryGirl.create(:admin_user))
        post_data = {:incoming_message => {:prominence => 'requester_only',
                                           :prominence_reason => 'boring'}}
        admin.put_via_redirect "/en/admin/incoming_messages/#{info_request.incoming_messages.first.id}", post_data
        admin.response.should be_success

        # Admin retains the requester only things
        inspect_zip_download(admin, info_request) do |zip|
          zip.count.should == 3
          zip.read('correspondence.txt').should match('hereisthetext')
        end

        # Zip for non owner is now without requester_only things
        inspect_zip_download(non_owner, info_request) do |zip|
          zip.count.should == 1
          correspondence_text = zip.read('correspondence.txt')
          correspondence_text.should_not match('hereisthetext')
          expected_text = 'This message has been hidden. boring'
          correspondence_text.should match(expected_text)
        end

        # Requester retains the requester only things
        owner = login(info_request.user)
        inspect_zip_download(owner, info_request) do |zip|
          zip.count.should == 3
          zip.read('correspondence.txt').should match('hereisthetext')
        end

      end

    end

    context 'when an outgoing message is made "requester_only"' do

      it 'should not include the outgoing message in a download of the entire request
                by a non-request owner but should retain them for owner and admin' do

        # Non-owner can download zip with incoming and attachments
        non_owner = login(FactoryGirl.create(:user))
        info_request = FactoryGirl.create(:info_request)

        inspect_zip_download(non_owner, info_request) do |zip|
          zip.count.should == 1
          zip.read('correspondence.txt').should match('Some information please')
        end

        # Admin makes the incoming message requester only
        admin = login(FactoryGirl.create(:admin_user))
        post_data = {:outgoing_message => {:prominence => 'requester_only',
                                           :prominence_reason => 'boring',
                                           :body => 'Some information please'}}
        admin.put_via_redirect "/en/admin/outgoing_messages/#{info_request.outgoing_messages.first.id}", post_data
        admin.response.should be_success

        # Admin retains the requester only things
        inspect_zip_download(admin, info_request) do |zip|
          zip.count.should == 1
          zip.read('correspondence.txt').should match('Some information please')
        end

        # Zip for non owner is now without requester_only things
        inspect_zip_download(non_owner, info_request) do |zip|
          zip.count.should == 1
          correspondence_text = zip.read('correspondence.txt')
          correspondence_text.should_not match('Some information please')
          expected_text = 'This message has been hidden. boring'
          correspondence_text.should match(expected_text)
        end

        # Requester retains the requester only things
        owner = login(info_request.user)
        inspect_zip_download(owner, info_request) do |zip|
          zip.count.should == 1
          zip.read('correspondence.txt').should match('Some information please')
        end

      end

    end

    it 'should successfully make a zipfile for an external request' do
      external_request = FactoryGirl.create(:external_request)
      user = login(FactoryGirl.create(:user))
      inspect_zip_download(user, external_request){ |zip|  zip.count.should == 1 }
    end
  end

end
