module RetryAfterDeletedAttachment

    # A method to mixin to retry once after finding that an attachment
    # was deleted on a reparse.  (This could also be used as an
    # around_filter, but the methods in question already have one.)

    def cope_with_attachment_deleted_after_reparse
        times_tried = 0
        begin
            yield
        rescue AttachmentDeletedByReparse
            times_tried += 1
            if times_tried > 1
                raise
            end
            retry
        end
    end

end
