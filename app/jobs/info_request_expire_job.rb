##
# Job to expire InfoRequest objects. Can expire single requests, all requests or
# a collection of requests through an model associations.
#
# Examples:
#   InfoRequestExpireJob.perform(InfoRequest.first)
#   InfoRequestExpireJob.perform(InfoRequest, :all)
#   InfoRequestExpireJob.perform(PublicBody.first, :info_requests)
#
class InfoRequestExpireJob < ApplicationJob
  queue_as :default

  def perform(object, method = nil)
    return object.expire if object.is_a?(InfoRequest)

    if object == InfoRequest && method == :all
      enumerator = InfoRequest.all
    else
      association = object.association(method)
      enumerator = association.reader if association.klass == InfoRequest
    end

    enumerator.find_each { |request| perform(request) }
  end
end
