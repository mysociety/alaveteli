module AlaveteliPro
  module ApplicationHelper
    # Send calls for x_path or x_url through to the main app if the main app
    # implements them. This means that all url/path helpers within the
    # engine will need to be namespaced: alaveteli_pro.some_path otherwise
    # they could be clobbered, but that's good practice, and it avoids the
    # the less palatable alternative, which is namespacing everything in
    # alaveteli core with main_app.some_path.
    def method_missing(method, *args, &block)
      if method.to_s.end_with?('_path', '_url') and main_app.respond_to?(method)
        main_app.send(method, *args)
      else
        super
      end
    end

    # Corrollary to the #method_missing hack here which lets us respond to
    # path/url helpers with the main_app's version of them.
    def respond_to?(method)
      if method.to_s.end_with?('_path', '_url') and main_app.respond_to?(method)
        main_app.send(method, *args)
      else
        super
      end
    end

    def site_name
      _("{{site_name}} Professional", site_name: AlaveteliConfiguration::site_name)
    end
  end
end
