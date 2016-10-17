class UpdateEventTypeWhenOnlyEditingProminenceToHide < ActiveRecord::Migration
  def up
    InfoRequestEvent.find_each do |event|
      event.update_attributes!(event_type: "hide") if event.only_editing_prominence_to_hide?
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
