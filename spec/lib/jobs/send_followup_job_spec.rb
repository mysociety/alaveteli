require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe SendFollowupJob do

    describe :initialize do

        it 'requires an outgoing message' do
            expect{ SendFollowupJob.new }.to raise_error(ArgumentError)
        end

    end

    describe :outgoing_message do

        it 'returns the outgoing message' do
            msg = FactoryGirl.build(:internal_review_request)
            job = SendFollowupJob.new(msg)
            expect(job.outgoing_message).to eq(msg)
        end

    end

    describe :info_request do

        it 'uses a default info_request' do
            msg = FactoryGirl.build(:internal_review_request)
            job = SendFollowupJob.new(msg)
            expect(job.info_request).to eq(msg.info_request)
        end

        it 'accepts an :info_request option' do
            msg = FactoryGirl.build(:internal_review_request)
            req = FactoryGirl.create(:info_request)
            job = SendFollowupJob.new(msg, :info_request => req)
            expect(job.info_request).to eq(req)
        end

    end

    describe :mail_message do

        it 'uses a default mail_message' do
            msg = FactoryGirl.build(:internal_review_request)
            job = SendFollowupJob.new(msg)
            expect(job.mail_message).to be_kind_of(Mail::Message)
        end

        it 'accepts a :mail_message option' do
            msg = FactoryGirl.build(:internal_review_request)
            mail = double('mail')
            job = SendFollowupJob.new(msg, :mail_message => mail)
            expect(job.mail_message).to eq(mail)
        end

    end

    describe :before do

        it 'prepares the outgoing message for sending' do
            msg = FactoryGirl.create(:internal_review_request)

            msg.should_receive(:info_request).at_least(:once).and_call_original
            msg.should_receive(:send_message).once

            job = SendFollowupJob.new(msg)
            job.before   
        end

    end

    describe :perform do

        it 'asks the mailer to deliver the message' do
            msg = double('outgoing_message', :info_request => double)
            mail = double('mailer')
            mail.should_receive(:deliver)

            job = SendFollowupJob.new(msg, :mail_message => mail)
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
        
            req.should_receive(:log_event).with('followup_sent', log_event_params).once
            # Don't care about described_state/what_doing
            req.should_receive(:described_state)
            msg.should_receive(:what_doing)

            job = SendFollowupJob.new(msg, :info_request => req, :mail_message => mail)
            job.after
        end

        it 'updates the state of the info request when it is waiting clarification' do
            msg = FactoryGirl.create(:internal_review_request, :what_doing => 'normal_sort')
            job = SendFollowupJob.new(msg)
            job.info_request.instance_variable_set(:@described_state, 'waiting_clarification')
            job.after
            expect(job.info_request.described_state).to eq('waiting_response')
        end

        it 'updates the state of the info request when the outgoing message is an internal review' do
            msg = FactoryGirl.create(:internal_review_request)
            msg.stub(:what_doing).and_return('internal_review')
            job = SendFollowupJob.new(msg)
            job.after
            expect(job.info_request.described_state).to eq('internal_review')
        end

    end

end
