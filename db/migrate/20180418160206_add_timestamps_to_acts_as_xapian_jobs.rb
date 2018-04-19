# -*- encoding : utf-8 -*-
class AddTimestampsToActsAsXapianJobs < ActiveRecord::Migration
  def change
    add_timestamps(:acts_as_xapian_jobs)
  end
end
