##
# This module provides sortable functionality for admin controllers.
# It allows controllers to easily add sorting capabilities to their actions by
# defining sortable attributes and handling sort parameters.
#
# Usage:
#   class Admin::UsersController < ApplicationController
#     include Admin::Sortable
#
#     sortable :name, :email, :created_at, default: :created_at_desc
#   end
#
module Admin::Sortable
  extend ActiveSupport::Concern

  included do
    helper_method :sort_options, :sort_query, :sort_order
  end

  class_methods do
    DEFAULT_SORTABLE_ATTRS = [:created_at, :updated_at]

    def sortable(*attrs, only: nil, except: nil)
      attrs = attrs.any? ? attrs : DEFAULT_SORTABLE_ATTRS

      before_action only: only, except: except do
        configure_sort_options(attrs)
        configure_sort_order
      end
    end
  end

  def sort_options
    @sort_options
  end

  def sort_order
    @sort_order
  end

  def sort_query
    @sort_options[@sort_order]
  end

  private

  def configure_sort_options(attrs)
    @sort_options = attrs.each_with_object({}) do |attr, h|
      h["#{attr}_asc"]  = "#{attr} ASC"
      h["#{attr}_desc"] = "#{attr} DESC"
    end.with_indifferent_access
  end

  def configure_sort_order
    @sort_order =
      if params[:sort_order].in?(@sort_options.keys)
        params[:sort_order]
      else
        @sort_options.keys.first
      end
  end
end
