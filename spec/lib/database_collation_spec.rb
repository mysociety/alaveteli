# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DatabaseCollation do

  describe '.supports?' do

    it 'delegates to an instance of the class' do
      collation = double
      allow(DatabaseCollation).to receive(:instance).and_return(collation)
      expect(collation).to receive(:supports?).with('en_GB')
      DatabaseCollation.supports?('en_GB')
    end

  end

  describe '.instance' do

    it 'creates a new instance' do
      expect(DatabaseCollation.instance).to be_instance_of(DatabaseCollation)
    end

    it 'caches the instance' do
      expect(DatabaseCollation.instance).to equal(DatabaseCollation.instance)
    end

    it 'configures the instance with the default connection' do
      expect(DatabaseCollation.instance.connection).
        to equal(DatabaseCollation::DEFAULT_CONNECTION)
    end

  end

  describe '.new' do

    it 'defaults to the ActiveRecord::Base connection' do
      expect(DatabaseCollation.new.connection).
        to eq(ActiveRecord::Base.connection)
    end

    it 'allows a connection to be specified' do
      mock_connection = double
      expect(DatabaseCollation.new(mock_connection).connection).
        to eq(mock_connection)
    end

  end

  describe '#supports?' do

    it 'does not support collation if the database is not postgresql' do
      database = DatabaseCollation.
                 new(mock_connection(:adapter_name => 'MySQL'))
      expect(database.supports?('en_GB')).to be false
    end

    it 'does not support collation if the postgresql version is too old' do
      database = DatabaseCollation.
                 new(mock_connection(:postgresql_version => 90111))
      expect(database.supports?('en_GB')).to be false
    end

    it 'does not support collation if the collation does not exist' do
      database = DatabaseCollation.new(mock_connection)
      expect(database.supports?('es')).to be false
    end

    it 'supports collation if the collation exists' do
      database = DatabaseCollation.new(mock_connection)
      expect(database.supports?('en_GB')).to be true
    end

  end

end

def mock_connection(connection_double_opts = {})
  # Connection must be PostgreSQL 90112 or greater
  default_double_opts = { :adapter_name => 'PostgreSQL',
                          :postgresql_version => 90112 }

  connection_double_opts = default_double_opts.merge(connection_double_opts)

  connection = double('ActiveRecord::FakeConnection', connection_double_opts)

  installed_collations = [
    { "collname" => "default" },
    { "collname" => "C" },
    { "collname" => "POSIX" },
    { "collname" => "C.UTF-8" },
    { "collname" => "en_GB" },
    { "collname" => "en_GB.utf8" }
  ]

  allow(connection).
    to receive(:execute).
      with(%q(SELECT collname FROM pg_collation;)).
        and_return(installed_collations)

  connection
end
