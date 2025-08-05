# -*- encoding : utf-8 -*-
module AlaveteliPro::PublicBodiesHelper
  def public_body_search_attributes(body)
    result = {
      id: body.id,
      name: body.name,
      short_name: body.short_name,
      notes: body.notes,
      info_requests_visible_count: body.info_requests_visible_count,
      about: _('About {{public_body_name}}', public_body_name: body.name)
    }

    # Work out which render method we need to use so this can be called from
    # controllers and views
    render_method = respond_to?(:render_to_string) ? :render_to_string : :render

    # Render the result for the JS, so that we can use Rails's pluralisation,
    # translation, etc
    result[:html] = public_send(
      render_method,
      partial: 'alaveteli_pro/public_bodies/search_result',
      layout: false,
      locals: { result: result }
    )

    result
  end
end
