require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe SendInitialRequestJob do

    describe :initialize do

        it 'requires an outgoing message' do
            expect{ SendInitialRequestJob.new }.to raise_error(ArgumentError)
        end

    end

    describe :outgoing_message do

        it 'returns the outgoing message' do
            msg = FactoryGirl.build(:initial_request)
            job = SendInitialRequestJob.new(msg)
            expect(job.outgoing_message).to eq(msg)
        end

    end

    describe :info_request do

        it 'uses a default info_request' do
            msg = FactoryGirl.build(:initial_request)
            job = SendInitialRequestJob.new(msg)
            expect(job.info_request).to eq(msg.info_request)
        end

        it 'accepts an :info_request option' do
            msg = FactoryGirl.build(:initial_request)
            req = FactoryGirl.create(:info_request)
            job = SendInitialRequestJob.new(msg, :info_request => req)
            expect(job.info_request).to eq(req)
        end

    end

    describe :mail_message do

        it 'uses a default mail_message' do
            msg = FactoryGirl.build(:initial_request)
            job = SendInitialRequestJob.new(msg)
            expect(job.mail_message).to be_kind_of(Mail::Message)
        end

        it 'accepts a :mail_message option' do
            msg = FactoryGirl.build(:initial_request)
            mail = double('mail')
            job = SendInitialRequestJob.new(msg, :mail_message => mail)
            expect(job.mail_message).to eq(mail)
        end

    end

    describe :before do

        it 'prepares the outgoing message for sending' do
            msg = FactoryGirl.create(:initial_request)

            msg.should_receive(:info_request).at_least(:once).and_call_original
            msg.should_receive(:send_message).once

            job = SendInitialRequestJob.new(msg)
            job.before            
        end

    end

    describe :perform do

        it 'asks the mailer to deliver the message' do
            msg = double('outgoing_message', :info_request => double)
            mail = double('mailer')
            mail.should_receive(:deliver)

            job = SendInitialRequestJob.new(msg, :mail_message => mail)
            job.perform
        end

    end

    describe :after do

        it 'logs the event with the info request' do
            msg = double('outgoing_message', :id => 1)
            req = double('info_request')
            mail = double('mail_message',
                          :message_id => 'ogm-16+5413122394a07-6f30@localhost',
                          :to_addrs => %w(test@example.com test@example.org))

            log_event_params = { :email => 'test@example.com, test@example.org',
                                 :outgoing_message_id => 1,
                                 :smtp_message_id => 'ogm-16+5413122394a07-6f30@localhost' }

            # Don't care about set_described_state as we test independently
            req.should_receive(:set_described_state).with(anything)
            req.should_receive(:log_event).with('sent', log_event_params).once

            job = SendInitialRequestJob.new(msg, :info_request => req, :mail_message => mail)
            job.after
        end

        it 'updates the state of the info request',
            :pending => 'info_request gets initialized with described_state ' \
            'of waiting_response so test passes with no implementation' do
            msg = FactoryGirl.create(:initial_request)
            job = SendInitialRequestJob.new(msg)
            job.after
            expect(job.info_request.described_state).to eq('waiting_response')
        end

    end

end
