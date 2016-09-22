module AlaveteliPro
  class Account < ActiveRecord::Base
    attr_accessible :user
    has_one :user, class_name: AlaveteliPro.user_class
  end
end
