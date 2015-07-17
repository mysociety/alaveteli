require 'csv'
require 'tempfile'

namespace :import do

  desc 'Import public bodies from CSV provided on standard input'
  task :import_csv => :environment do
    dryrun = ENV['DRYRUN'] != '0'
    if dryrun
      STDERR.puts "Only a dry run; public bodies will not be created"
    end

    tmp_csv = nil
    Tempfile.open('alaveteli') do |f|
      f.write STDIN.read
      tmp_csv = f
    end

    number_of_rows = 0

    STDERR.puts "Preliminary check for ambiguous names or slugs..."

    # Check that the name and slugified version of the name are
    # unique:
    url_part_count = Hash.new { 0 }
    name_count = Hash.new { 0 }
    reader = CSV.open tmp_csv.path, 'r'
    header_line = reader.shift
    headers = header_line.collect { |h| h.gsub /^#/, ''}

      reader.each do |row_array|
        row = Hash[headers.zip row_array]
        name = row['name']
        url_part = MySociety::Format::simplify_url_part name, "body"
        name_count[name] += 1
        url_part_count[url_part] += 1
        number_of_rows += 1
      end

      non_unique_error = false

      [[name_count, 'name'],
      [url_part_count, 'url_part']].each do |counter, field|
        counter.sort.map do |name, count|
          if count > 1
            non_unique_error = true
            STDERR.puts "The #{field} #{name} was found #{count} times."
          end
        end
      end

      next if non_unique_error

      STDERR.puts "Now importing the public bodies..."

      # Now it's (probably) safe to try to import:
      errors, notes = PublicBody.import_csv_from_file(tmp_csv.path,
                                                      tag='',
                                                      tag_behaviour='replace',
                                                      dryrun,
                                                      editor="#{ENV['USER']} (Unix user)",
      I18n.available_locales) do |row_number, fields|
        percent_complete = (100 * row_number.to_f / number_of_rows).to_i
        STDERR.print "#{row_number} out of #{number_of_rows} "
        STDERR.puts "(#{percent_complete}% complete)"
      end

      if errors.length > 0
        STDERR.puts "Import failed, with the following errors:"
        errors.each do |error|
          STDERR.puts "  #{error}"
        end
      else
        STDERR.puts "Done."
      end

      end
      end
