# -*- encoding : utf-8 -*-
module AlaveteliPro::InfoRequestsHelper
  def publish_at_options
    options = { _("Publish immediately") => '' }
    options.merge(AlaveteliPro::Embargo::DURATION_LABELS.invert)
  end

  def embargo_extension_options
    AlaveteliPro::Embargo::DURATION_LABELS.invert
  end

  def body_for_selectize(body)
    {
      id: body.id,
      name: body.name,
      notes: ActionController::Base.helpers.truncate(
        ActionController::Base.helpers.strip_tags(body.notes),
        length: 150
      ),
      info_requests_visible_count: body.info_requests_visible_count
    }.to_json
  end

  def public_body_options(selected = nil)
    bodies = PublicBody.visible.map do |pb|
      [pb.name, pb.id, { 'data-data' => body_for_selectize(pb) }]
    end
    options_for_select(bodies, selected)
  end
end
