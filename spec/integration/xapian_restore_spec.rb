require 'spec_helper'

require 'rake'
Rails.application.load_tasks
load 'lib/acts_as_xapian/tasks/restore.rake'

describe '`rake xapian:restore:...` tasks' do

  before do
    ActsAsXapian.readable_init
  end

  it 'can restore old Xapian database' do
    existing_pb = FactoryGirl.create(:public_body, name: 'Existing Body')

    # make sure DB is up to date for fixtures data
    create_fixtures_xapian_index

    # take a backup of the DB
    backup_xapian_index
    ENV['XAPIAN_BACKUP_DATE'] = Time.now.to_s

    # advance time
    allow(Time).to receive(:now).and_return(Time.now + 1.week)

    # make changes
    new_pb = FactoryGirl.create(:public_body, name: 'New Body')
    existing_pb.update(name: 'Changed Body')

    # make sure changes have been indexed
    update_xapian_index

    # check searches work before the incident
    result(PublicBody, 'New Body').to eq(new_pb)
    result(PublicBody, 'Existing Body').to be_nil
    result(PublicBody, 'Changed Body').to eq(existing_pb)

    # disaster strikes, restore old backup
    drop_xapian_index
    restore_xapian_index

    # search should now fail
    result(PublicBody, 'New Body').to be_nil
    result(PublicBody, 'Existing Body').to eq(existing_pb)
    result(PublicBody, 'Changed Body').to be_nil

    # restore DB
    run('queue_events_to_reindex')
    update_xapian_index
    run('queue_obsolete_indexes_for_removal')
    update_xapian_index
    run('second_pass')
    update_xapian_index

    # check all the previous searches work
    result(PublicBody, 'New Body').to eq(new_pb)
    result(PublicBody, 'Existing Body').to be_nil
    result(PublicBody, 'Changed Body').to eq(existing_pb)
  end

  def result(model, term)
    object = ActsAsXapian::Search.new([model], term, limit: 1)
    result = object.results[0]
    expect(result && result[:model])
  end

  def run(command)
    Rake.application.invoke_task("xapian:restore:#{command}")
  end

end
