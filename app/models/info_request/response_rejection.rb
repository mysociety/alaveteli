class InfoRequest
  module ResponseRejection
    class UnknownResponseRejectionError < ArgumentError; end

    SPECIALIZED_CLASSES = { 'bounce' => Bounce,
                            'holding_pen' => HoldingPen,
                            'blackhole' => Base,
                            'discard' => Base }

    def self.for(name, info_request, mail)
      SPECIALIZED_CLASSES.fetch(name).new(info_request, mail)
    rescue KeyError
      raise UnknownResponseRejectionError,
            "Unknown allow_new_responses_from '#{ name }'"
    end
  end
end
