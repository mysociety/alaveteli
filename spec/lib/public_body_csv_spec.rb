require 'spec_helper'

RSpec.describe PublicBodyCSV do

  describe '.default_fields' do

    it 'has a default set of fields' do
      defaults = [:id,
                  :name,
                  :short_name,
                  :url_name,
                  :tag_string,
                  :calculated_home_page,
                  :publication_scheme,
                  :disclosure_log,
                  :notes_as_string,
                  :created_at,
                  :updated_at,
                  :version]
      expect(PublicBodyCSV.default_fields).to eq(defaults)
    end
  end

  describe '.default_headers' do

    it 'has a default set of headers' do
      defaults = ['Internal ID',
                  'Name',
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

  describe '.export' do
    it 'should return a valid CSV file with the right number of rows/columns' do
      all_data = CSV.parse(PublicBodyCSV.export)
      expect(all_data.length).to eq(7)
      # Check that the header has the right number of columns:
      expect(all_data[0].length).to eq(12)
      # And an actual line of data:
      expect(all_data[1].length).to eq(12)
    end

    it 'only includes visible bodies' do
      PublicBody.internal_admin_body
      all_data = CSV.parse(PublicBodyCSV.export)
      expect(all_data.map(&:first)).to_not include('Internal admin authority')
    end

    it 'does not include site_administration bodies' do
      FactoryBot.create(
        :public_body, name: 'Site Admin Body', tag_string: 'site_administration'
      )

      all_data = CSV.parse(PublicBodyCSV.export)
      expect(all_data.map(&:first)).to_not include('Site Admin Body')
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
      csv = PublicBodyCSV.new(fields: custom_fields)
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
      csv = PublicBodyCSV.new(headers: custom_headers)
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
      attrs = { name: 'Exported to CSV',
                short_name: 'CSV',
                request_email: 'csv@localhost',
                tag_string: 'exported',
                note_body: 'An exported authority',
                created_at: '2007-10-25 10:51:01 UTC',
                updated_at: '2007-10-25 10:51:01 UTC' }
      body = FactoryBot.create(:public_body, :with_note, attrs)

      csv = PublicBodyCSV.new
      csv << body

      expected = ["#{body.id},Exported to CSV,CSV,csv,exported,https://www.localhost,\"\",\"\",An exported authority,2007-10-25 10:51:01 UTC,2007-10-25 10:51:01 UTC,1"]
      expect(csv.rows).to eq(expected)
    end

  end

  describe '#generate' do

    it 'generates the csv' do
      attrs1 = { name: 'Exported to CSV 1',
                 short_name: 'CSV1',
                 request_email: 'csv1@localhost',
                 tag_string: 'exported',
                 note_body: 'An exported authority',
                 created_at: '2007-10-25 10:51:01 UTC',
                 updated_at: '2007-10-25 10:51:01 UTC' }
      body1 = FactoryBot.create(:public_body, :with_note, attrs1)

      attrs2 = { name: 'Exported to CSV 2',
                 short_name: 'CSV2',
                 request_email: 'csv2@localhost',
                 tag_string: 'exported',
                 note_body: 'Exported authority',
                 created_at: '2011-01-26 14:11:02 UTC',
                 updated_at: '2011-01-26 14:11:02 UTC' }
      body2 = FactoryBot.create(:public_body, :with_note, attrs2)

      expected = <<-CSV.strip_heredoc
      Name,Short name,URL name,Home page,Publication scheme,Disclosure log,Notes,Created at,Updated at,Version
      Exported to CSV 1,CSV1,csv1,https://www.localhost,"","",An exported authority,2007-10-25 10:51:01 UTC,2007-10-25 10:51:01 UTC,1
      Exported to CSV 2,CSV2,csv2,https://www.localhost,"","",Exported authority,2011-01-26 14:11:02 UTC,2011-01-26 14:11:02 UTC,1
      CSV

      # Miss out the tags field because the specs keep changing the order
      # that the tags are returned in
      fields = [:name, :short_name, :url_name, :calculated_home_page, :publication_scheme, :disclosure_log, :notes_as_string, :created_at, :updated_at, :version]
      headers = ['Name', 'Short name', 'URL name', 'Home page', 'Publication scheme', 'Disclosure log', 'Notes', 'Created at', 'Updated at', 'Version']

      csv = PublicBodyCSV.new(fields: fields, headers: headers)
      csv << body1
      csv << body2
      expect(csv.generate).to eq(expected)
    end

  end

end
