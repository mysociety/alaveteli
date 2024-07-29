require 'spec_helper'

RSpec.describe 'health checks' do
  before do
    # create recent content and destroy pending jobs to satisfy checks.
    FactoryBot.create(:user)
    FactoryBot.create(:info_request)
    FactoryBot.create(:incoming_message)
    ActsAsXapian::ActsAsXapianJob.destroy_all
  end

  def status
    get '/health/checks'
    response.status
  end

  it { expect(status).to eq 200 }

  it 'should succeed when Xapain job was queued within the last hour' do
    travel_to(59.minutes.ago)
    ActsAsXapian::ActsAsXapianJob.create(
      model_id: InfoRequestEvent.first.id,
      model: 'InfoRequestEvent',
      action: 'update'
    )
    expect(status).to eq 200 # initial run to cache ID and Time in Redis

    travel_back
    expect(status).to eq 200
  end

  it 'should fail when Xapain job was queued over an hour ago' do
    travel_to(1.hour.ago)
    ActsAsXapian::ActsAsXapianJob.create(
      model_id: 1, model: 'InfoRequestEvent', action: 'update'
    )
    expect(status).to eq 200 # initial run to cache ID and Time in Redis

    travel_back
    expect(status).to eq 500
  end

  it 'should succeed when oldest Xapain job changes during the hour' do
    travel_to(1.hour.ago)
    job1 = ActsAsXapian::ActsAsXapianJob.create(
      model_id: 1, model: 'InfoRequestEvent', action: 'update'
    )
    ActsAsXapian::ActsAsXapianJob.create(
      model_id: 2, model: 'InfoRequestEvent', action: 'update'
    )
    expect(status).to eq 200 # initial run to cache ID and Time in Redis

    job1.destroy

    travel_back
    expect(status).to eq 200
  end
end
