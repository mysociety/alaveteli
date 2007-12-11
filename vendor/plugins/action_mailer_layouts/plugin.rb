module ActionMailer
  class Base

    # Specify the layout name
    adv_attr_accessor :layout
    
    alias_method :render_message_without_layouts, :render_message

    def render_message(method_name, body)
      layout = @layout ? @layout.to_s : self.class.to_s.underscore
      md = /^([^\.]+)\.([^\.]+\.[^\.]+)\.(rhtml|rxml)$/.match(method_name)
      layout << ".#{md.captures[1]}" if md && md.captures[1]
      layout << ".rhtml"
      if File.exists?(File.join(layouts_path, layout))
        body[:content_for_layout] = render_message_without_layouts(method_name, body)
        initialize_layout_template_class(body).render(:file => layout)
      else
        render_message_without_layouts(method_name, body)
      end
    end
    
    def initialize_layout_template_class(assigns)
      returning(template = ActionView::Base.new(layouts_path, assigns, self)) do
        template.extend self.class.master_helper_module
      end
    end
  
    def layouts_path
      File.join(template_root, 'layouts')
    end  
  end
end