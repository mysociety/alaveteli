require 'spec_helper'

describe DatabaseCollation do

  describe '.supports?' do

    it 'delegates to an instance of the class' do
      collation = double
      connection = mock_connection
      allow(ActiveRecord::Base.connection_pool).to receive(:with_connection).and_yield(connection)
      allow(DatabaseCollation).to receive(:new).with(connection).and_return(collation)
      expect(collation).to receive(:supports?).with('en_GB')
      DatabaseCollation.supports?('en_GB')
    end

  end

  describe '.new' do

    it 'requires a connection to be specified' do
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

    it 'does not support collation if the collation has a different encoding' do
      database = DatabaseCollation.new(mock_connection)
      expect(database.supports?('en_GB.utf8')).to be false
    end

    it 'supports collation if the collation exists for current encoding' do
      database = DatabaseCollation.new(mock_connection)
      expect(database.supports?('en_GB')).to be true
    end

    it 'supports installed collations with "-1" (universal) encoding' do
      database = DatabaseCollation.new(mock_connection)
      expect(database.supports?('default')).to be true
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
    { "collname" => "default", "collencoding" => "-1"},
    { "collname" => "C", "collencoding" => "-1" },
    { "collname" => "POSIX", "collencoding" => "-1" },
    { "collname" => "C.UTF-8", "collencoding" => "6" },
    { "collname" => "en_GB", "collencoding" => "8" },
    { "collname" => "en_GB.utf8", "collencoding" => "6" }
  ]

  allow(connection).to receive(:current_database).and_return("alaveteli_test")

  allow(connection).
    to receive(:execute).
      with("SELECT encoding FROM pg_database WHERE datname = " \
           "'alaveteli_test';").
      and_return([{ "encoding" => "8" }])

  # Simulate SQL filtering of returned collations
  allow(connection).
    to receive(:execute).
      with("SELECT collname FROM pg_collation " \
           "WHERE collencoding = '-1' OR collencoding = '8';").
        and_return(filter_collations(installed_collations, %w(-1 8)))

  connection
end

def filter_collations(collations, encodings)
  collations.
    select { |collation| encodings.include?(collation["collencoding"]) }
end
