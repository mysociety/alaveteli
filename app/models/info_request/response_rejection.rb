# -*- encoding : utf-8 -*-
class InfoRequest
  module ResponseRejection
    class UnknownResponseRejectionError < ArgumentError ; end

    SPECIALIZED_CLASSES = { 'bounce' => Bounce,
                            'holding_pen' => HoldingPen,
                            'blackhole' => Base,
                            'discard' => Base }

    def self.for(name, info_request, email, raw_email)
      SPECIALIZED_CLASSES.fetch(name).new(info_request, email, raw_email)
    rescue KeyError
      raise UnknownResponseRejectionError,
            "Unknown allow_new_responses_from '#{ name }'"
    end
  end
end
