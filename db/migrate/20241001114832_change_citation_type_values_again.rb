class ChangeCitationTypeValuesAgain < ActiveRecord::Migration[7.0]
  CHANGES = {
    'academic' => 'research'
  }

  def up
    perform(CHANGES)
  end

  def down
    perform(CHANGES.invert)
  end

  private

  def perform(data)
    data.each_pair do |before, after|
      Citation.where(type: before).update_all(type: after)
    end
  end
end
