# -*- encoding : utf-8 -*-
class InfoRequest
  module ResponseGatekeeper
    class Nobody < Base
      def initialize(info_request)
        super
        @allow = false
        @reason = _('This request has been set by an administrator to ' \
                    '"allow new responses from nobody"')
      end
    end
  end
end
