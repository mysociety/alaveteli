ActionDispatch::Routing::RouteSet::NamedRouteCollection::UrlHelper.class_eval do
  def self.optimize_helper?(_route)
    false
  end
end
