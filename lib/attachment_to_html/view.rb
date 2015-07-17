# -*- encoding : utf-8 -*-
module AttachmentToHTML
  class View < ERB

    def self.template
      @template || "#{ File.dirname(__FILE__) }/template.html.erb"
    end

    def self.template=(path)
      @template = path
    end

    attr_accessor :title, :body, :template, :wrapper

    def initialize(adapter, opts = {})
      self.title    = adapter.title
      self.body     = adapter.body
      self.template = opts.fetch(:template, self.class.template)
      self.wrapper  = opts.fetch(:wrapper, 'wrapper')
      super(File.read(template))
    end

    def render(&block)
      instance_eval(&block) if block_given?
      result(binding)
    end

    def content_for(area)
      send(area) if respond_to?(area)
    end

    private

    def inject_content(area, &block)
      instance_variable_set("@#{ area }".to_sym, block.call)
      self.class.send(:attr_accessor, area)
    end

  end
end
