class InfoRequestBatchMailerPreview < ActionMailer::Preview
  def batch_sent
    InfoRequestBatchMailer.batch_sent(info_request_batch, unrequestable, user)
  end

  private

  def info_request_batch
    InfoRequestBatch.new(
      id: 1,
      title: 'My batch request'
    )
  end

  def unrequestable
    [PublicBody.first]
  end

  def user
    User.first
  end
end
