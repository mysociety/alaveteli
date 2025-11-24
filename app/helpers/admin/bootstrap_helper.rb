# Helpers for working with Bootstrap elements within the admin interface
module Admin::BootstrapHelper
  def nav_li(path)
    tag.li class: nav_li_class(path) do
      yield
    end
  end

  private

  def nav_li_class(path)
    'active' if current_page?(path)
  end
end
