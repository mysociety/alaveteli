module AlaveteliPro
  class Account < ActiveRecord::Base
    attr_accessible :user
    belongs_to :user, class_name: AlaveteliPro.user_class
  end
end
