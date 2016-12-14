# -*- encoding : utf-8 -*-
ActiveRecord::Base.class_eval do
  include ActiveModel::ForbiddenAttributesProtection
end
