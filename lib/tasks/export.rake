# -*- coding: utf-8 -*-
#rake tasks and supporting models and functions to do research export
namespace :export do

require 'csv'
require 'fileutils'

#create models to access join and translation tables
class InfoRequestBatchPublicBody < ActiveRecord::Base
  self.table_name = "info_request_batches_public_bodies"
  belongs_to :info_request_batch
  belongs_to :public_body
  default_scope -> { order("info_request_batch_id ASC, public_body_id ASC") }
end

class PublicBodyCategoryTranslation < ActiveRecord::Base
  self.table_name = "public_body_category_translations"
  belongs_to :public_body_category
end

class PublicBodyHeadingTranslation < ActiveRecord::Base
  self.table_name = "public_body_heading_translations"
  belongs_to :public_body_heading
end

class HasTagStringTag < ActiveRecord::Base
  self.table_name = "has_tag_string_tags"
end




#Tries to pick up gender from the first name
def detects_gender(name)
    gender_d = GenderDetector.new # gender detector
    parts = name.split(" ")
    first_name = parts[0] #assumption!
    gender_d.get_gender(first_name, :great_britain).to_s
end

gender_lambda = lambda {|x| detects_gender(x.name)}

# Returns a lambda to pass to export function that censors x.property
def name_censor_lambda(property)
  lambda do |x|
    case_insensitive_user_censor(x.send(property), x.info_request.user)
  end
end

# Remove all instances of user's name (if there is a user), otherwise
#  return the original text unchanged
#
# text - the raw text that needs redaction
# user - the user object (may be nil)
#
# Returns a String
def case_insensitive_user_censor(text, user)
  if user && text
    text.gsub(/#{user.name}/i, "<REQUESTER>")
  else
    text
  end
end

# Returns a lambda to pass to export function that censors x.property
def name_censor_lambda(property)
  lambda do |x|
    case_insensitive_user_censor(x.send(property), x.info_request.user)
  end
end

# clunky wrapper for Rails' find_each method to cope with tables that
# don't have an integer type primary key
def find_each_record(model)
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
def csv_export(model, to_run, query=nil, header=nil, override={}, header_map={})
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


def process_data(filename, display_header, column_data, overrides, query)
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

def handle_error(err, data)
  p "---"
  puts "Error processing data:"
  puts err.message
  puts err.backtrace
  puts data.inspect
  p ""
end

def is_required?(model_name, to_run)
  return true unless to_run
  to_run.include?(model_name)
end

desc 'exports all non-personal information to export folder'
task :research_export => :environment do
  cut_off_date = ENV["CUTOFF_DATE"]
  to_run = ENV["MODELS"]

  if cut_off_date
    cut_off_date = Date.parse(cut_off_date)
  else
    cut_off_date = Date.today
  end

  to_run = to_run.split(",") if to_run

  csv_export(PublicBodyCategory, to_run)
  csv_export(PublicBodyHeading, to_run)
  csv_export(PublicBodyCategoryLink, to_run)
  csv_export(PublicBodyCategoryTranslation, to_run)
  csv_export(PublicBodyHeadingTranslation, to_run)
  csv_export(InfoRequestBatch, to_run)
  csv_export(InfoRequestBatchPublicBody, to_run)
  csv_export(HasTagStringTag, to_run, HasTagStringTag.where(model:"PublicBody"))

  #export public body information
  csv_export( PublicBody,
              to_run,
              PublicBody.where("created_at < ?", cut_off_date),
              ["id",
              "short_name",
              "created_at",
              "updated_at",
              "url_name",
              "home_page",
              "info_requests_count",
              "info_requests_successful_count",
              "info_requests_not_held_count",
              "info_requests_overdue_count",
              "info_requests_visible_classified_count",
              "info_requests_visible_count"])

  #export non-personal user fields
  csv_export( User,
              to_run,
              User.where(ban_text: '').
                where("updated_at < ?", cut_off_date),
              ["id",
              "name",
              "info_requests_count",
              "track_things_count",
              "request_classifications_count",
              "public_body_change_requests_count",
              "info_request_batches_count",
              ],
              override = {
               "name" => gender_lambda,
              },
              header_map = {
              "name" => "gender",
              }
              )

  #export InfoRequest Fields
  csv_export(InfoRequest,
             to_run,
             InfoRequest.where(prominence: "normal").
               where("updated_at < ?", cut_off_date),
             ["id",
              "title",
              "user_id",
              "public_body_id",
              "created_at",
              "updated_at",
              "described_state",
              "awaiting_description",
              "url_title",
              "law_used",
              "last_public_response_at",
              "info_request_batch_id"
             ])

  #export incoming messages - only where normal prominence,
  # allow name_censor to some fields
  csv_export(IncomingMessage,
             to_run,
             IncomingMessage.includes(:info_request).
               where(prominence: "normal").
               where("info_requests.prominence = ?","normal").
               where("incoming_messages.updated_at < ?", cut_off_date),
             ["id",
              "info_request_id",
              "created_at",
              "updated_at",
              "raw_email_id",
              "cached_attachment_text_clipped",
              "cached_main_body_text_folded",
              "cached_main_body_text_unfolded",
              "subject",
              "sent_at",
              "prominence"],
              override = {
                "cached_attachment_text_clipped" => name_censor_lambda('cached_attachment_text_clipped'),
                "cached_main_body_text_folded" => name_censor_lambda('cached_attachment_text_clipped'),
                "cached_main_body_text_unfolded" => name_censor_lambda('cached_attachment_text_clipped'),
              })

  #export incoming messages - only where normal prominence, allow name_censor to some fields
  csv_export(OutgoingMessage,
             to_run,
             OutgoingMessage.includes(:info_request).
               where(prominence:"normal").
               where("info_requests.prominence = ?","normal").
               where("outgoing_messages.updated_at < ?", cut_off_date),
             ["id",
              "info_request_id",
              "created_at",
              "updated_at",
              "body",
              "message_type",
              "subject",
              "last_sent_at",
              "incoming_message_followup_id"
             ],
             override = {
               "body" => name_censor_lambda('body'),
             })

  #export incoming messages - only where normal prominence, allow name_censor to some fields
  csv_export(FoiAttachment,
             to_run,
             FoiAttachment.joins(incoming_message: :info_request).
                           where("info_requests.prominence = ?","normal").
                           where("incoming_messages.updated_at < ?", cut_off_date),
             ["id",
              "content_type",
              "filename",
              "charset",
              "url_part_number",
              "incoming_message_id",
              "within_rfc822_subject"])

  end

end
