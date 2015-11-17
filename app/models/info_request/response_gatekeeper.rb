# -*- encoding : utf-8 -*-
class InfoRequest
  module ResponseGatekeeper
    class UnknownResponseGatekeeperError < ArgumentError ; end

    SPECIALIZED_CLASSES = { 'nobody' => Nobody,
                            'anybody' => Base,
                            'authority_only' => AuthorityOnly }

    def self.for(name, info_request)
      SPECIALIZED_CLASSES.fetch(name).new(info_request)
    rescue KeyError
      raise UnknownResponseGatekeeperError,
            "Unknown allow_new_responses_from '#{ name }'"
    end
  end
end
