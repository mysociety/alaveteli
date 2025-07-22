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
#   # Check for all actions:
#   read_only
#
#   # Check for specific actions:
#   read_only only: [:create, :update, :destroy]
#
#   # Check for all actions except specific ones:
#   read_only except: [:index, :show]
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
module ReadOnly
  extend ActiveSupport::Concern

  # Class methods to be added to the including class
  module ClassMethods
    # Define which actions should be checked for read-only status
    #
    # @param options [Hash] Options for the before_action callback
    # @option options [Array<Symbol>] :only Actions to limit the callback to
    # @option options [Array<Symbol>] :except Actions to exclude from the callback
    def read_only(**options)
      before_action(options) do |controller|
        controller.send(:check_read_only)
      end
    end
  end

  private

  # Check if the site is in general read-only mode
  #
  # @return [Boolean] true if a read-only redirect was performed, false otherwise
  def check_read_only
    unless AlaveteliConfiguration.read_only.empty?
      if feature_enabled?(:annotations)
        flash[:notice] = {
          partial: "general/read_only_annotations",
          locals: {
            site_name: site_name,
            read_only: AlaveteliConfiguration.read_only
          }
        }
      else
        flash[:notice] = {
          partial: "general/read_only",
          locals: {
            site_name: site_name,
            read_only: AlaveteliConfiguration.read_only
          }
        }
      end
      redirect_to frontpage_url
    end
  end
end
