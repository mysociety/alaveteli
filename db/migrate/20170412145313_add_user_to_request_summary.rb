# -*- encoding : utf-8 -*-
class AddUserToRequestSummary <  ActiveRecord::Migration[4.2] # 4.1
  def change
    add_reference :request_summaries, :user, index: true, null: false
  end
end
