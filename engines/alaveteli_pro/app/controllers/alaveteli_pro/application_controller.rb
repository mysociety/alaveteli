module AlaveteliPro
  class ApplicationController < ::ApplicationController
    def authenticate!
      if AlaveteliPro.user_authentication_method.respond_to? :call
        instance_eval AlaveteliPro.user_authentication_method
      elsif AlaveteliPro.user_authentication_method.is_a? Symbol
        send AlaveteliPro.user_authentication_method
      else
        raise(Error, "user_authentication_method must be a callable or a symbol")
      end
    end
  end
end
