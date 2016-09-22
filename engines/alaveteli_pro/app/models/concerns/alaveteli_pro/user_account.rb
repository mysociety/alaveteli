module AlaveteliPro
  module UserAccount
    extend ActiveSupport::Concern

    included do
      has_one :account, class_name: 'AlaveteliPro::Account'
    end

    def is_pro_user?
      account.nil?
    end
  end
end