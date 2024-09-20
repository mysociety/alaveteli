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
# This class represents a job for anonymizing text using an external command.
#
class Workflow::Jobs::AnonymizeText < Workflow::Job
  def perform
    file = Tempfile.new
    file.write(source)
    file.flush

    cmd = [ENV['REDACT_COMMAND'], '--file', file.path].join(' ')
    IO.popen(cmd, &:read)

  ensure
    file.close
  end

  def content_type
    'text/plain'
  end
end
