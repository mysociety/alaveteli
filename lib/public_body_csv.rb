# -*- encoding : utf-8 -*-
require 'csv'

# Public: Generate a CSV representation of PublicBody instances
#
# Examples
#
#   bodies = PublicBody.search('useless')
#
#   csv = PublicBodyCSV.new(:fields => [:name, :calculated_home_page],
#                           :headers => ['Name', 'Home Page'])
#
#   bodies.each { |body| csv << body }
#
#   csv.generate
#   # => Name,Home Page
#        Department for Humpadinking,http://localhost
#        Ministry of Silly Walks,http://www.localhost
#        Department of Loneliness,http://localhost
class PublicBodyCSV

  def self.default_fields
    [:name,
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
  end

  # TODO: Generate headers from fields
  def self.default_headers
    ['Name',
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
  end

  attr_reader :fields, :headers, :rows

  def initialize(args = {})
    @fields = args.fetch(:fields, self.class.default_fields)
    @headers = args.fetch(:headers, self.class.default_headers)
    @rows = []
  end

  def <<(public_body)
    # Allow join_rows to handle newlines because of differences between
    # CSV.generate_line in 1.8 / 1.9+
    if RUBY_VERSION.to_f >= 1.9
      rows << CSV.generate_line(collect_public_body_attributes(public_body), :row_sep => '')
    else
      rows << CSV.generate_line(collect_public_body_attributes(public_body))
    end
  end

  # TODO: Just use CSV.generate when Ruby 1.8.7 support is dropped
  def generate
    csv = generate_header_row
    csv << join_rows
    csv << "\n"
  end

  private

  def join_rows
    rows.join("\n")
  end

  def generate_header_row
    # Add a newline because of differences between
    # CSV.generate_line in 1.8 / 1.9+
    row = CSV.generate_line(headers)
    row += "\n" unless RUBY_VERSION.to_f >= 1.9
    row
  end

  def collect_public_body_attributes(public_body)
    fields.map do |field|
      public_body.respond_to?(field) ? public_body.send(field) : ''
    end
  end

end
