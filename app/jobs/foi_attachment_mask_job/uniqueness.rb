##
# Module to add methods to check for existing jobs before performing/enqueuing
# attempting to ensure we execute once only.
#
# These methods only work if Sidekiq is used as the ActiveJob adapter.
#
module FoiAttachmentMaskJob::Uniqueness
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def perform_once_later(attachment)
      perform_later(attachment) unless existing_job(attachment)
    end

    def perform_once_now(attachment)
      existing_job(attachment)&.delete
      perform_now(attachment)
    end

    def existing_job(attachment)
      return unless queue_adapter.is_a?(
        ActiveJob::QueueAdapters::SidekiqAdapter
      )

      queue = Sidekiq::Queue.new(queue_name)
      queue.find do |j|
        gid = j.display_args.first['_aj_globalid']
        gid == attachment.to_gid.to_s
      end
    end
  end
end
