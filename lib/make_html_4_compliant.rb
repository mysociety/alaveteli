# Monkeypatch! Output HTML 4.0 compliant code, using method described in this
# ticket: http://dev.rubyonrails.org/ticket/6009

ActionView::Helpers::TagHelper.module_eval do
  def tag(name, options = nil, open = false, escape = true)
    "<#{name}#{tag_options(options, escape) if options}" + (open ? ">" : ">")
  end
end

