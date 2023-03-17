module AdminHelper
  include Admin::BootstrapHelper
  include Admin::CensorRulesHelper
  include Admin::LinkHelper
  include Admin::ProminenceHelper

  def icon(name)
    content_tag(:i, "", class: "icon-#{name}")
  end

  def eye
    icon("eye-open")
  end

  def chevron_right
    icon("chevron-right")
  end

  def chevron_down
    icon("chevron-down")
  end

  def arrow_right
    icon("arrow-right")
  end

  def comment_visibility(comment)
    comment.visible? ? 'Visible' : 'Hidden'
  end

  def sort_order_humanized(sort_order)
    { 'name_asc' => 'Name ▲',
      'name_desc' => 'Name ▼',
      'created_at_asc' => 'Oldest',
      'created_at_desc' => 'Newest',
      'updated_at_asc' => 'Least Recently Updated',
      'updated_at_desc' => 'Recently Updated' }.
    fetch(sort_order.to_s) { sort_order.to_s.titleize }
  end

  def significant_event_params(event)
    params = { 'edit' => [:title, :described_state, :awaiting_description],
               'edit_comment' => [:body],
               'edit_outgoing' => [:body] }
    params.fetch(event.event_type, [])
  end

  def event_params_description(event)
    text = ''
    if can?(:admin, AlaveteliPro::Embargo) || !event.info_request.embargo
      diff = event.params_diff
      significant_event_params(event).each do |key|
        if diff[:new].key? key
          text += "Changed #{key} from '#{diff[:old][key]}' to '#{diff[:new][key]}'. "
         end
      end
    end
    text
  end

  def highlight_allow_new_responses_from(string)
    case string
    when 'authority_only'
      content_tag :span, string, class: 'text-warning'
    when 'nobody'
      content_tag :span, string, class: 'text-error'
    else
      string
    end
  end
end
