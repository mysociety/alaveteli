##
# Job to expire InfoRequest objects. Can expire single requests, all requests or
# a collection of requests through an model associations.
#
# Examples:
#   InfoRequest::ExpireJob.perform(InfoRequest.first)
#   InfoRequest::ExpireJob.perform(InfoRequest, :all)
#   InfoRequest::ExpireJob.perform(PublicBody.first, :info_requests)
#
class InfoRequest::ExpireJob < ApplicationJob
  queue_as :xapian

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
