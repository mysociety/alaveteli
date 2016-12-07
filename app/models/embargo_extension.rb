class EmbargoExtension < ActiveRecord::Base
  belongs_to :embargo
  validates_presence_of :embargo_id
  validates_presence_of :extension_duration
  validates_inclusion_of :extension_duration,
                         in: lambda { |e| Embargo.new.allowed_durations }
end
