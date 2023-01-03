# Methods to handle pagination within an associated InfoRequestBatch
module InfoRequest::BatchPagination
  def next_in_batch
    return nil unless info_request_batch
    batch_sibling_requests_ordered_by_id[index_in_batch + 1] || first_in_batch
  end

  def prev_in_batch
    return nil unless info_request_batch
    batch_sibling_requests_ordered_by_id[index_in_batch - 1]
  end

  private

  def first_in_batch
    batch_sibling_requests_ordered_by_id.first
  end

  def index_in_batch
    batch_sibling_requests_ordered_by_id.pluck(:id).index(id)
  end

  def batch_sibling_requests_ordered_by_id
    info_request_batch.info_requests.reorder(id: :asc)
  end
end
