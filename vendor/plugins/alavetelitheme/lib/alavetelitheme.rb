class ActionController::Base
    before_filter :set_view_paths

    def set_view_paths         
        self.prepend_view_path File.join(File.dirname(__FILE__), "views")
    end
end
