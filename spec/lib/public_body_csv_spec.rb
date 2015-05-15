# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PublicBodyCSV do

    describe '.default_fields' do
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
        PublicBodyCSV.default_fields.should == defaults
    end

    describe '.default_headers' do
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
        PublicBodyCSV.default_headers.should == defaults
    end

    describe :fields do

        it 'has a default set of fields' do
            csv = PublicBodyCSV.new
            csv.fields.should == PublicBodyCSV.default_fields
        end

        # DO NOT include request_email (we don't want to make it
        # easy to spam all authorities with requests)
        it 'does not include the request_email attribute' do
            csv = PublicBodyCSV.new
            csv.fields.should_not include(:request_email)
        end

        it 'allows custom fields to be set on instantiation' do
            custom_fields = [:name, :short_name]
            csv = PublicBodyCSV.new(:fields => custom_fields)
            csv.fields.should == custom_fields
        end

    end

    describe :headers do

        it 'has a default set of headers' do
            csv = PublicBodyCSV.new
            csv.headers.should == PublicBodyCSV.default_headers
        end

        it 'allows custom headers to be set on instantiation' do
            custom_headers = ['Name', 'Short Name']
            csv = PublicBodyCSV.new(:headers => custom_headers)
            csv.headers.should == custom_headers
        end

    end

    describe :rows do

        it 'is empty on instantiation' do
            csv = PublicBodyCSV.new
            csv.rows.should be_empty
        end

    end

    describe :<< do

        it 'adds an elements attributes to the rows collection' do
            csv = PublicBodyCSV.new
            expected = ["Ministry of Silly Walks,MSW,msw,useless_agency,http://www.localhost,\"\",\"\",You know the one.,2007-10-25 10:51:01 UTC,2007-10-25 10:51:01 UTC,1"]
            csv << PublicBody.find(5)
            csv.rows.should == expected
        end

    end

    describe :generate do

        it 'generates the csv' do
            expected = <<-CSV
Name,Short name,URL name,Home page,Publication scheme,Disclosure log,Notes,Created at,Updated at,Version
Department for Humpadinking,DfH,dfh,http://www.localhost,"","",An albatross told me!!!,2007-10-25 10:51:01 UTC,2007-10-25 10:51:01 UTC,2
Department of Loneliness,DoL,lonely,http://www.localhost,"","",A very lonely public body that no one has corresponded with,2011-01-26 14:11:02 UTC,2011-01-26 14:11:02 UTC,1
CSV

            # Miss out the tags field because the specs keep changing the order
            # that the tags are returned in
            fields = [:name, :short_name, :url_name, :calculated_home_page, :publication_scheme, :disclosure_log, :notes, :created_at, :updated_at, :version]
            headers = ['Name', 'Short name', 'URL name', 'Home page', 'Publication scheme', 'Disclosure log', 'Notes', 'Created at', 'Updated at', 'Version']

            csv = PublicBodyCSV.new(:fields => fields, :headers => headers)
            csv << PublicBody.where(:name => 'Department for Humpadinking').first
            csv << PublicBody.where(:name => 'Department of Loneliness').first
            csv.generate.should == expected
        end

    end

end
