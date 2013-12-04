# Temporary patches for Rails security alert made on 03/12/2013

# CVE-2013-6414 https://groups.google.com/forum/#!topic/rubyonrails-security/A-ebV4WxzKg

ActiveSupport.on_load(:action_view) do
  ActionView::LookupContext::DetailsKey.class_eval do
    class << self
      alias :old_get :get

      def get(details)
        if details[:formats]
          details = details.dup
          syms    = Set.new Mime::SET.symbols
          details[:formats] = details[:formats].select { |v|
            syms.include? v
          }
        end
        old_get details
      end
    end
  end
end
