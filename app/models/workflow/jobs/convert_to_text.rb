# == Schema Information
# Schema version: 20240905062817
#
# Table name: workflow_jobs
#
#  id            :bigint           not null, primary key
#  type          :string
#  resource_type :string
#  resource_id   :bigint
#  status        :integer
#  parent_id     :bigint
#  metadata      :jsonb
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

##
# This class is responsible for converting HTML content to plain text.
#
class Workflow::Jobs::ConvertToText < Workflow::Job
  include ActionView::Helpers::SanitizeHelper

  def perform
    strip_tags(sanitize(source))
  end

  def content_type
    'text/plain'
  end
end
