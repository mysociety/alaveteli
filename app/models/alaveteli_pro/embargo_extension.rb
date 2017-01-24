# == Schema Information
#
# Table name: embargo_extensions
#
#  id                 :integer          not null, primary key
#  embargo_id         :integer
#  extension_duration :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
module AlaveteliPro
  class EmbargoExtension < ActiveRecord::Base
    belongs_to :embargo
    validates_presence_of :embargo_id
    validates_presence_of :extension_duration
    validates_inclusion_of :extension_duration,
                           in: lambda { |e| AlaveteliPro::Embargo.new.allowed_durations }
  end
end
