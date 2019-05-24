# -*- encoding : utf-8 -*-
class AddTimestampsToActsAsXapianJobs < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:acts_as_xapian_jobs, null: true)
  end
end
