module ActionMailer
  class Base

    # Specify the layout name
    adv_attr_accessor :layout
    
    alias_method :render_message_without_layouts, :render_message

    def render_message(method_name, body)
      layout = @layout ? @layout.to_s.clone : self.class.to_s.underscore
      
      filename = if method_name.respond_to?(:filename)
        method_name.filename
      else
        method_name
      end
          
      md = /([^\.]+)\.([^\.]+\.[^\.]+)\.(erb|rhtml|rxml)$/.match(filename)
      
      layout << ".#{md.captures[1]}" if md && md.captures[1]
      layout << ".#{md.captures[2]}" if md && md.captures[2]

      if File.exists?(File.join(layouts_path, layout))
        body[:content_for_layout] = render_message_without_layouts(method_name, body)
        
        # TODO: extract content_for blocks and somehow put them in body[:content_for_...]
        
        initialize_layout_template_class(body).render(:file => "/#{layout}")
      else
        render_message_without_layouts(method_name, body)
      end
    end
    
    def initialize_layout_template_class(assigns)
      # for Rails 2.1 (and greater), we have to process view paths first!
      ActionView::TemplateFinder.process_view_paths(layouts_path) if defined?(ActionView::TemplateFinder)
      
      returning(template = ActionView::Base.new(layouts_path, assigns, self)) do
        template.extend self.class.master_helper_module
        template.extend ActionView::Helpers::CaptureHelper
      end
    end
  
    def layouts_path
      File.join(template_root, 'layouts')
    end  
  end
end