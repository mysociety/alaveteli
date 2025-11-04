# ReadOnly Concern
# ----------------
#
# This concern provides a consistent way to handle read-only mode across the
# application. It allows controllers to specify which features they want to
# check for read-only status and automatically handles redirecting users when
# those features are in read-only mode.
#
# Features:
# - Define read-only checks for specific features or entire controllers
# - Specify which actions should be checked
# - Integrates with CanCanCan abilities
# - Centralized configuration via AlaveteliConfiguration
#
# Usage in Controllers:
# --------------------
#
# class MyController < ApplicationController
#   include ReadOnly
#
#   # Check a single feature for all actions:
#   read_only :comments
#
#   # Check multiple features for all actions:
#   read_only :classifications, :comments
#
#   # Check a feature for specific actions:
#   read_only :feature1, only: [:create, :update, :destroy]
#
#   # Check a feature for all actions except specific ones:
#   read_only :feature2, except: [:index, :show]
#
#   # Check the global read-only status for specific actions:
#   read_only only: [:create]
# end
#
# Configuration:
# -------------
#
# Read-only status is controlled through AlaveteliConfiguration:
#
# 1. Global read-only mode:
#    Set READ_ONLY to a non-empty value
#
# 2. Feature-specific read-only mode:
#    Set READ_ONLY_FEATURES to an array of feature names
#
module ReadOnly
  extend ActiveSupport::Concern

  # Class methods to be added to the including class
  module ClassMethods
    # Define which features should be checked for read-only status
    #
    # @param feature [Symbol, String, nil] The feature to check for read-only
    #   status (optional)
    # @param options [Hash] Options for the before_action callback
    # @option options [Array<Symbol>] :only Actions to limit the callback to
    # @option options [Array<Symbol>] :except Actions to exclude from the
    #   callback
    def read_only(*feature, **options)
      prepend_before_action(options) do |controller|
        controller.send(:check_read_only_feature, feature[0])
      end
    end
  end

  private

  # Check if a specific feature is in read-only mode
  #
  # @param feature [Symbol, String] The feature to check
  # @return [Boolean] true if a read-only redirect was performed, false
  #   otherwise
  def check_read_only_feature(feature)
    return false unless read_only_feature?(feature)

    flash[:notice] = _("{{site_name}} is currently in maintenance. {{message}}",
                       site_name: site_name, message: read_only_message)

    redirect_to frontpage_url
  end

  def read_only?
    read_only_message.present?
  end

  def read_only_message
    AlaveteliConfiguration.read_only
  end

  def read_only_feature?(feature)
    read_only? ||
      (feature && read_only_features.include?(feature.to_sym))
  end

  def read_only_features
    AlaveteliConfiguration.read_only_features.map(&:to_sym)
  end
end
