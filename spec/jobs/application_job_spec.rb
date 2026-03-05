require 'spec_helper'

RSpec.describe ApplicationJob, type: :job do
  include ActiveJob::TestHelper

  before do
    stub_const('FailingJob', Class.new(ApplicationJob) do
      def perform(*_args)
        raise StandardError, 'test error'
      end
    end)
  end

  describe 'retry_on StandardError' do
    context 'when exception notifications are enabled' do
      before do
        allow(AlaveteliConfiguration).to receive(:exception_notifications_from).
          and_return('from@example.com')
        allow(AlaveteliConfiguration).to receive(:exception_notifications_to).
          and_return('to@example.com')
      end

      it 'sends exception notification once after all 5 retries exhausted' do
        attempts = 0

        allow_any_instance_of(FailingJob).to receive(:perform).
          and_wrap_original do
            attempts += 1
            raise StandardError, 'test error'
          end
        allow_any_instance_of(FailingJob).to receive(:job_id).and_return(123456)

        expected_data = {
          job: 'FailingJob', job_id: 123456, job_arguments: ['arg1', 'arg2']
        }

        expect(ExceptionNotifier).to receive(:notify_exception).
          with(instance_of(StandardError), data: expected_data).once

        perform_enqueued_jobs { FailingJob.perform_later('arg1', 'arg2') }

        expect(attempts).to eq(5)
      end
    end

    context 'when exception notifications are disabled' do
      before do
        allow(AlaveteliConfiguration).to receive(:exception_notifications_from).
          and_return('')
        allow(AlaveteliConfiguration).to receive(:exception_notifications_to).
          and_return('')
      end

      it 'does not send exception notification' do
        expect(ExceptionNotifier).not_to receive(:notify_exception)

        perform_enqueued_jobs { FailingJob.perform_later('arg1', 'arg2') }
      end
    end
  end
end
