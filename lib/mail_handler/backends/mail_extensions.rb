module Mail
    class Message
        attr_accessor :url_part_number
        attr_accessor :rfc822_attachment # when a whole email message is attached as text
        attr_accessor :within_rfc822_attachment # for parts within a message attached as text (for getting subject mainly)
        attr_accessor :count_parts_count
        attr_accessor :count_first_uudecode_count

        # A patched version of the message initializer to work around a bug where stripping the original
        # input removes meaningful spaces - e.g. in the case of uuencoded bodies.
        def initialize(*args, &block)
            @body = nil
            @body_raw = nil
            @separate_parts = false
            @text_part = nil
            @html_part = nil
            @errors = nil
            @header = nil
            @charset = 'UTF-8'
            @defaulted_charset = true

            @perform_deliveries = true
            @raise_delivery_errors = true

            @delivery_handler = nil

            @delivery_method = Mail.delivery_method.dup

            @transport_encoding = Mail::Encodings.get_encoding('7bit')

            @mark_for_delete = false

            if args.flatten.first.respond_to?(:each_pair)
                init_with_hash(args.flatten.first)
            else
                # The replacement of this commented out line is the change.
                # init_with_string(args.flatten[0].to_s.strip)
                init_with_string(args.flatten[0].to_s)
            end

            if block_given?
                instance_eval(&block)
            end

            self
        end
    end
end