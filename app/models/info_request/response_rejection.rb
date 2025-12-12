class InfoRequest
  module ResponseRejection
    class UnknownResponseRejectionError < ArgumentError; end

    SPECIALIZED_CLASSES = { 'bounce' => Bounce,
                            'holding_pen' => HoldingPen,
                            'blackhole' => Base,
                            'discard' => Base }

    def self.for(name, info_request, mail, inbound_email)
      SPECIALIZED_CLASSES.fetch(name).new(info_request, mail, inbound_email)
    rescue KeyError
      raise UnknownResponseRejectionError,
            "Unknown allow_new_responses_from '#{ name }'"
    end
  end
end
