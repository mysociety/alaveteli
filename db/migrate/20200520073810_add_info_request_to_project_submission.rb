class AddInfoRequestToProjectSubmission < ActiveRecord::Migration[5.1]
  def change
    add_reference :project_submissions, :info_request
  end
end
