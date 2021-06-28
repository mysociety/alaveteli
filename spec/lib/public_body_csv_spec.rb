require 'spec_helper'

describe PublicBodyCSV do

  describe '.default_fields' do

    it 'has a default set of fields' do
      defaults = [:name,
                  :short_name,
                  :url_name,
                  :tag_string,
                  :calculated_home_page,
                  :publication_scheme,
                  :disclosure_log,
                  :notes,
                  :created_at,
                  :updated_at,
                  :version]
      expect(PublicBodyCSV.default_fields).to eq(defaults)
    end
  end

  describe '.default_headers' do

    it 'has a default set of headers' do
      defaults = ['Name',
                  'Short name',
                  'URL name',
                  'Tags',
                  'Home page',
                  'Publication scheme',
                  'Disclosure log',
                  'Notes',
                  'Created at',
                  'Updated at',
                  'Version']
      expect(PublicBodyCSV.default_headers).to eq(defaults)
    end
  end

  describe '#fields' do

    it 'has a default set of fields' do
      csv = PublicBodyCSV.new
      expect(csv.fields).to eq(PublicBodyCSV.default_fields)
    end

    # DO NOT include request_email (we don't want to make it
    # easy to spam all authorities with requests)
    it 'does not include the request_email attribute' do
      csv = PublicBodyCSV.new
      expect(csv.fields).not_to include(:request_email)
    end

    it 'allows custom fields to be set on instantiation' do
      custom_fields = [:name, :short_name]
      csv = PublicBodyCSV.new(:fields => custom_fields)
      expect(csv.fields).to eq(custom_fields)
    end

  end

  describe '#headers' do

    it 'has a default set of headers' do
      csv = PublicBodyCSV.new
      expect(csv.headers).to eq(PublicBodyCSV.default_headers)
    end

    it 'allows custom headers to be set on instantiation' do
      custom_headers = ['Name', 'Short Name']
      csv = PublicBodyCSV.new(:headers => custom_headers)
      expect(csv.headers).to eq(custom_headers)
    end

  end

  describe '#rows' do

    it 'is empty on instantiation' do
      csv = PublicBodyCSV.new
      expect(csv.rows).to be_empty
    end

  end

  describe '#<<' do

    it 'adds an elements attributes to the rows collection' do
      attrs = { :name => 'Exported to CSV',
                :short_name => 'CSV',
                :request_email => 'csv@localhost',
                :tag_string => 'exported',
                :notes => 'An exported authority',
                :created_at => '2007-10-25 10:51:01 UTC',
                :updated_at => '2007-10-25 10:51:01 UTC' }
      body = FactoryBot.create(:public_body, attrs)

      csv = PublicBodyCSV.new
      csv << body

      expected = ["Exported to CSV,CSV,csv,exported,http://www.localhost,\"\",\"\",An exported authority,2007-10-25 10:51:01 UTC,2007-10-25 10:51:01 UTC,1"]
      expect(csv.rows).to eq(expected)
    end

  end

  describe '#generate' do

    it 'generates the csv' do
      attrs1 = { :name => 'Exported to CSV 1',
                 :short_name => 'CSV1',
                 :request_email => 'csv1@localhost',
                 :tag_string => 'exported',
                 :notes => 'An exported authority',
                 :created_at => '2007-10-25 10:51:01 UTC',
                 :updated_at => '2007-10-25 10:51:01 UTC' }
      body1 = FactoryBot.create(:public_body, attrs1)

      attrs2 = { :name => 'Exported to CSV 2',
                 :short_name => 'CSV2',
                 :request_email => 'csv2@localhost',
                 :tag_string => 'exported',
                 :notes => 'Exported authority',
                 :created_at => '2011-01-26 14:11:02 UTC',
                 :updated_at => '2011-01-26 14:11:02 UTC' }
      body2 = FactoryBot.create(:public_body, attrs2)

      expected = <<-CSV.strip_heredoc
      Name,Short name,URL name,Home page,Publication scheme,Disclosure log,Notes,Created at,Updated at,Version
      Exported to CSV 1,CSV1,csv1,http://www.localhost,"","",An exported authority,2007-10-25 10:51:01 UTC,2007-10-25 10:51:01 UTC,1
      Exported to CSV 2,CSV2,csv2,http://www.localhost,"","",Exported authority,2011-01-26 14:11:02 UTC,2011-01-26 14:11:02 UTC,1
      CSV

      # Miss out the tags field because the specs keep changing the order
      # that the tags are returned in
      fields = [:name, :short_name, :url_name, :calculated_home_page, :publication_scheme, :disclosure_log, :notes, :created_at, :updated_at, :version]
      headers = ['Name', 'Short name', 'URL name', 'Home page', 'Publication scheme', 'Disclosure log', 'Notes', 'Created at', 'Updated at', 'Version']

      csv = PublicBodyCSV.new(:fields => fields, :headers => headers)
      csv << body1
      csv << body2
      expect(csv.generate).to eq(expected)
    end

  end

end
