if Rails.pre_version5?

  module ActionDispatch
    module Integration
      class Session
        alias :old_process :process

        def process(method, path, options = nil, _a = nil)
          options ||= {}
          params = options.delete(:params) || {}
          old_process(method, path, params, options)
        end
      end
    end
  end

  module ActionController
    class TestCase
      module Behavior
        alias :old_process :process

        def process(action, method, options = nil, _a = nil, _b = nil)
          options ||= {}

          if options.delete(:xhr)
            xml_http_request(method.downcase, action, options)

          else
            params = options.delete(:params) || {}
            session = options.delete(:session) || {}
            flash = options.delete(:flash) || {}

            old_process(action, method, params, session, flash)
          end
        end
      end
    end
  end

end
