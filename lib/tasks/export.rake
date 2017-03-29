# -*- coding: utf-8 -*-
#rake tasks and supporting models and functions to do research export
namespace :export do

load 'lib/data_export.rb'

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

  DataExport.csv_export(PublicBodyCategory, to_run)
  DataExport.csv_export(PublicBodyHeading, to_run)
  DataExport.csv_export(PublicBodyCategoryLink, to_run)
  DataExport.csv_export(PublicBodyCategoryTranslation, to_run)
  DataExport.csv_export(PublicBodyHeadingTranslation, to_run)
  DataExport.csv_export(InfoRequestBatchPublicBody, to_run)
  DataExport.csv_export(HasTagStringTag,
                        to_run,
                        HasTagStringTag.where(model:"PublicBody"))

  #export public body information
  DataExport.csv_export( PublicBody,
              to_run,
              PublicBody.where("created_at < ?", cut_off_date),
              ["id",
              "name",
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
  DataExport.csv_export( User,
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
               "name" => DataExport.gender_lambda,
              },
              header_map = {
              "name" => "gender",
              }
              )

  #export InfoRequest Fields
  DataExport.csv_export(InfoRequest,
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

  DataExport.csv_export(InfoRequestBatch,
               to_run,
               InfoRequestBatch.where("updated_at < ?", cut_off_date),
               ["id",
                "title",
                "user_id",
                "sent_at",
                "created_at",
                "updated_at"])

  #export incoming messages - only where normal prominence,
  # allow name_censor to some fields
  DataExport.csv_export(IncomingMessage,
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
                "cached_attachment_text_clipped" => DataExport.name_censor_lambda('cached_attachment_text_clipped'),
                "cached_main_body_text_folded" => DataExport.name_censor_lambda('cached_main_body_text_folded'),
                "cached_main_body_text_unfolded" => DataExport.name_censor_lambda('cached_main_body_text_unfolded'),
              })

  #export incoming messages - only where normal prominence, allow name_censor to some fields
  DataExport.csv_export(OutgoingMessage,
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
               "body" => DataExport.name_censor_lambda('body'),
             })

  #export incoming messages - only where normal prominence, allow name_censor to some fields
  DataExport.csv_export(FoiAttachment,
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
