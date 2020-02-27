module AlaveteliPro::BatchRequest
  extend ActiveSupport::Concern

  included do
    helper_method :mode, :category_tag
  end

  private

  def mode
    valid_modes = %w(search browse)
    @mode ||= if valid_modes.include?(params[:mode])
                params[:mode]
              else
                valid_modes.first
      end
  end

  def category_tag
    params[:category_tag]
  end
end
