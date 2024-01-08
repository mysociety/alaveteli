# Helpers for the Holding Pen
module Admin::HoldingPenHelper
  def guess_badge(score)
    badge_style =
      case score * 100
      when 100    then 'badge-success'
      when 70..99 then 'badge-info'
      when 11..69 then 'badge-warning'
      when 1..10  then 'badge-important'
      end

    tag.span class: ['badge', badge_style].compact.join(' ') do
      yield
    end
  end
end
