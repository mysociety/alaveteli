class AddUserToRequestSummary < ActiveRecord::Migration
  def change
    add_reference :request_summaries, :user, index: true, null: false
  end
end
