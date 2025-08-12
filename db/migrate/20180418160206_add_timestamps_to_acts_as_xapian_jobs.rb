class AddTimestampsToActsAsXapianJobs < ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:acts_as_xapian_jobs, null: true)
  end
end
