# -*- encoding : utf-8 -*-
#
# Public: methods for exporting redacted data for research use

class DataExport
  require 'csv'
  require 'fileutils'

  def self.exportable_requests(cut_off_date)
    InfoRequest.
      is_public.
      where(prominence: "normal").
      where("info_requests.updated_at < ?", cut_off_date)
  end

  def self.exportable_incoming_messages(cut_off_date)
    IncomingMessage.
      includes(:info_request).references(:info_requests).
      references(info_request: :embargoes).
      joins('LEFT OUTER JOIN embargoes
               ON embargoes.info_request_id = info_requests.id').
      where('embargoes.id IS NULL').
      where("info_requests.prominence = ?", "normal").
      where("incoming_messages.prominence = ?", "normal").
      where("incoming_messages.updated_at < ?", cut_off_date)
  end

  def self.exportable_outgoing_messages(cut_off_date)
    OutgoingMessage.
      includes(:info_request).references(:info_requests).
      references(info_request: :embargoes).
      joins('LEFT OUTER JOIN embargoes
               ON embargoes.info_request_id = info_requests.id').
      where('embargoes.id IS NULL').
      where("outgoing_messages.prominence = ?", "normal").
      where("info_requests.prominence = ?", "normal").
      where("outgoing_messages.updated_at < ?", cut_off_date)
  end

  def self.exportable_foi_attachments(cut_off_date)
    FoiAttachment.
      joins(incoming_message: :info_request).
      references(incoming_message: :info_requests).
      references(info_request: :embargoes).
      joins('LEFT OUTER JOIN embargoes
               ON embargoes.info_request_id = info_requests.id').
      where('embargoes.id IS NULL').
      where("info_requests.prominence = ?", "normal").
      where("incoming_messages.prominence = ?", "normal").
      where("incoming_messages.updated_at < ?", cut_off_date)
  end

  #Tries to pick up gender from the first name
  def self.detects_gender(name)
    gender_d = GenderDetector.new # gender detector
    parts = name.split(" ")
    first_name = parts[0] #assumption!
    gender_d.get_gender(first_name, :great_britain).to_s
  end

  def self.gender_lambda
    lambda {|x| detects_gender(x.name)}
  end

  # Remove all instances of user's name (if there is a user), otherwise
  #  return the original text unchanged
  #
  # text - the raw text that needs redaction
  # user - the user object (may be nil)
  #
  # Returns a String
  def self.case_insensitive_user_censor(text, user)
    if user && text
      text.gsub(/#{user.name}/i, "<REQUESTER>")
    else
      text
    end
  end

  # Returns a lambda to pass to export function that censors x.property
  def self.name_censor_lambda(property)
    lambda do |x|
      if x.respond_to?(:info_request)
        case_insensitive_user_censor(x.send(property), x.info_request.user)
      else
        case_insensitive_user_censor(x.send(property), x.user)
      end
    end
  end

  # clunky wrapper for Rails' find_each method to cope with tables that
  # don't have an integer type primary key
  def self.find_each_record(model)
    # if the model has a primary key and the primary key is an integer
    if model.primary_key && model.columns_hash[model.primary_key].type == :integer
      model.find_each { |record| yield record }
    else
      limit = 1000
      offset = 0
      while offset <= model.count
        model.limit(limit).offset(offset).each { |record| yield record }
        offset += limit
      end
    end
  end

  # Exports a model
  #
  # query    - a query used to limit the export to matching records
  # header   - used to restrict exported columns
  # override - pass in lambdas to modify a given column based on values in the row
  #
  # Returns a String
  def self.csv_export(model, to_run, query=nil, header=nil, override={}, header_map={})
    return unless is_required?(model.name, to_run)
    # set query and header to default values unless supplied
    query  ||= model
    header ||= model.column_names

    now = Time.now.strftime("%d-%m-%Y")
    filename = "exports/#{model.name}-#{now}.csv"
    FileUtils.mkdir_p('exports')
    puts "exporting to: #{filename}"

    #allow header names to be changed if we're transforming them enough they're a diff column
    display_header = []
    header.each do |h|
      if header_map.key?(h) #do we have an override for this column name?
        display_header.append(header_map[h])
      else
        display_header.append(h)
      end
    end

    process_data(filename, display_header, header, override, query)
  end


  def self.process_data(filename, display_header, column_data, overrides, query)
    CSV.open(filename, "wb") do |csv|
      csv << display_header
      find_each_record(query) do |model_instance|
        line  = []
        # iterate over columns to create an array of data to make a line of csv
        column_data.each do |attribute|
          if overrides.key?(attribute) #do we have an override for this column?
            begin
              line << overrides[attribute][model_instance] #if so send to lambda
            rescue Exception => err
              handle_error(err, line)
              next # something went wrong, stop processing this data row
            end
          else
            line << model_instance.send(attribute)
          end
        end
        begin
          csv << line
        rescue ArgumentError => err
          handle_error(err, line)
        end
      end
    end
  end

  def self.is_required?(model_name, to_run)
    return true unless to_run
    to_run.include?(model_name)
  end

  private

  def self.handle_error(err, data)
    p "---"
    puts "Error processing data:"
    puts err.message
    puts err.backtrace
    puts data.inspect
    p ""
  end

end
