# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20210114161442
#
# Table name: embargo_extensions
#
#  id                 :integer          not null, primary key
#  embargo_id         :integer
#  extension_duration :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

module AlaveteliPro
  class EmbargoExtension < ApplicationRecord
    belongs_to :embargo,
               :inverse_of => :embargo_extensions
    validates_presence_of :embargo
    validates_presence_of :extension_duration
    validates_inclusion_of :extension_duration,
                           in: lambda { |e| AlaveteliPro::Embargo.new.allowed_durations }
  end
end
