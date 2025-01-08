class ChangeCitationTypeValues < ActiveRecord::Migration[7.0]
  CHANGES = {
    'news_story' => 'journalism',
    'academic_paper' => 'academic'
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
