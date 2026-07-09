require 'spec_helper'

RSpec.describe LowPriorityWorker, type: :job do
  class TestLowPriorityJob < ApplicationJob
    include LowPriorityWorker
    def perform; end
  end

  after :each do
    Current.bot_request = false
  end

  it 'routes to default queue for normal requests' do
    Current.bot_request = false
    job = TestLowPriorityJob.new
    expect(job.queue_name).to eq('default')
  end

  it 'routes to bulk_processor queue for bot requests' do
    Current.bot_request = true
    job = TestLowPriorityJob.new
    expect(job.queue_name).to eq('bulk_processor')
  end
end
