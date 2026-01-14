# Various methods for handling `FoiAttachment` records associated with
# `IncomingMessage` records
module IncomingMessage::Attachments
  extend ActiveSupport::Concern

  UnableToExtractAttachments = Class.new(StandardError)

  MAX_ATTACHMENT_TEXT_CLIPPED = 1_000_000 # 1Mb ish

  included do
    has_many :foi_attachments,
             -> { order(:id) },
             inverse_of: :incoming_message,
             dependent: :destroy,
             autosave: true
  end

  class_methods do
    # And look up by URL part number and display filename to get an attachment
    # TODO: relies on extract_attachments calling
    # MailHandler.ensure_parts_counted
    # The filename here is passed from the URL parameter, so it's the
    # display_filename rather than the real filename.
    # rubocop:disable Layout/LineLength
    def get_attachment_by_url_part_number_and_filename(attachments, found_url_part_number, display_filename)
      # rubocop:enable Layout/LineLength
      attachment_by_part_number = attachments.detect do |a|
        a.url_part_number == found_url_part_number
      end

      filename_matches =
        attachment_by_part_number &&
        attachment_by_part_number.display_filename == display_filename

      if filename_matches
        # Then the filename matches, which is fine:
        attachment_by_part_number
      else
        # Otherwise if the URL part number and filename don't
        # match - this is probably due to a reparsing of the
        # email.  In that case, try to find a unique matching
        # filename from any attachment.
        attachments_by_filename = attachments.select do |a|
          a.display_filename == display_filename
        end

        attachments_by_filename[0] if attachments_by_filename.length == 1
      end
    end

    # rubocop:disable Layout/LineLength
    def get_attachment_by_url_part_number_and_filename!(attachments, found_url_part_number, display_filename)
      # rubocop:enable Layout/LineLength
      attachment = get_attachment_by_url_part_number_and_filename(
        attachments, found_url_part_number, display_filename
      )

      return unless attachment

      # check filename in URL matches that in database (use a censor rule if you
      # want to change a filename)
      if attachment.display_filename != display_filename &&
         attachment.old_display_filename != display_filename
        msg = 'please use same filename as original file has, display: '
        msg += "'#{ attachment.display_filename }' "
        msg += 'old_display: '
        msg += "'#{ attachment.old_display_filename }' "
        msg += 'original: '
        msg += "'#{ display_filename }'"
        raise ActiveRecord::RecordNotFound, msg
      end

      attachment
    end
  end

  def get_attachments_for_display # rubocop:disable Naming/AccessorMethodName
    parse_raw_email
    # return what user would consider attachments, i.e. not the main body
    main_part = get_main_body_text_part
    attachments = []
    foi_attachments.each do |attachment|
      attachments << attachment if attachment != main_part
    end
    attachments
  end

  def extract_attachments!
    extract_attachments
    save!
  end

  # Returns text version of attachment text
  # TODO: This could be a private method – it is only called by IncomingMessage
  # and is directly tested.
  def get_attachment_text_full # rubocop:disable Naming/AccessorMethodName
    text = _get_attachment_text_internal

    # This can be useful for memory debugging
    # puts 'xxx ' + MySociety::DebugHelpers.allocated_string_size_around_gc

    # Save clipped version for snippets
    if cached_attachment_text_clipped.nil?
      clipped = text.mb_chars[0..MAX_ATTACHMENT_TEXT_CLIPPED].delete("\0")
      self.cached_attachment_text_clipped = clipped
      save!
    end

    text
  end

  # Returns a version reduced to a sensible maximum size - this
  # is for performance reasons when showing snippets in search results.
  def get_attachment_text_clipped # rubocop:disable Naming/AccessorMethodName
    if cached_attachment_text_clipped.nil?
      # As side effect, get_attachment_text_full makes snippet text
      attachment_text = get_attachment_text_full
      raise "internal error" if cached_attachment_text_clipped.nil?
    end

    cached_attachment_text_clipped
  end

  # Returns space separated list of file extensions of attachments to this
  # message. Defaults to the normal extension for known mime type, otherwise
  # uses other extensions.
  def get_present_file_extensions # rubocop:disable Naming/AccessorMethodName
    ret = {}
    get_attachments_for_display.each do |attachment|
      ext = AlaveteliFileTypes.mimetype_to_extension(attachment.content_type)
      if ext.nil? && !attachment.filename.nil?
        ext = File.extname(attachment.filename).gsub(/^[.]/, "")
      end
      ret[ext] = 1 unless ext.nil?
    end
    ret.keys.join(" ")
  end

  private

  def _get_attachment_text_internal
    # Extract text from each attachment
    get_attachments_for_display.reduce('') { |memo, attachment|
      return memo if Ability.guest.cannot?(:read, attachment)

      text = MailHandler.get_attachment_text_one_file(
        attachment.content_type, attachment.default_body, attachment.charset
      )
      text = convert_string_to_utf8(text, 'UTF-8').string
      text = apply_masks(text, 'text/html') unless attachment.locked?

      memo += text
    }
  end

  # rubocop:disable Lint::UnderscorePrefixedVariableName
  def extract_attachments
    _mail = raw_email.mail!
    attachment_attributes = MailHandler.get_attachment_attributes(_mail)
    attachment_attributes = attachment_attributes.inject({}) do |memo, attrs|
      attrs.delete(:original_body)
      memo[attrs[:hexdigest]] = attrs
      memo
    end

    attachments = attachment_attributes.map do |hexdigest, attrs|
      attachment = foi_attachments.find_or_initialize_by(hexdigest: hexdigest)
      attachment.attributes = attrs
      attachment
    end

    # Get the main body part from the set of attachments not from the
    # foi_attachments association - some of the total set of foi_attachments may
    # now be obsolete. Sometimes (e.g. when parsing mail from Apple Mail) we can
    # end up with less attachments because the hexdigest of an attachment is
    # identical.
    main_part = get_main_body_text_part(attachments)

    # We don't use get_main_body_text_internal, as we want to avoid charset
    # conversions, since _uudecode_attachments needs to deal with those.
    # e.g. for https://secure.mysociety.org/admin/foi/request/show_raw_email/24550
    if main_part
      c = _mail.count_first_uudecode_count
      attachments += _uudecode_attachments(main_part.body, c)
    end

    # Purge old public attachments that will be rebuilt with a new hexdigest
    old_attachments = (foi_attachments - attachments)

    non_public_old_attachments = old_attachments.reject(&:is_public?)
    if non_public_old_attachments.any?
      # if there are non public attachments error as we don't want to re-build
      # and lose the prominence as this will make them public
      raise UnableToExtractAttachments, "unable to extract attachments due " \
        "to prominence of attachments " \
        "(ID=#{non_public_old_attachments.map(&:id).join(', ')})"
    end

    locked_old_attachments = old_attachments.select(&:locked?)
    if locked_old_attachments.any?
      # if there are locked attachments error as we don't want to re-build and
      # lose any changes made outside Alaveteli
      raise UnableToExtractAttachments, "unable to extract attachments due " \
        "to locked attachments " \
        "(ID=#{locked_old_attachments.map(&:id).join(', ')})"
    end

    old_attachments.each(&:mark_for_destruction)
  end
  # rubocop:enable Lint::UnderscorePrefixedVariableName

  # Returns attachments that are uuencoded in main body part
  def _uudecode_attachments(text, start_part_number)
    MailHandler.uudecode(text, start_part_number).map do |attrs|
      hexdigest = attrs.delete(:hexdigest)
      attachment = foi_attachments.find_or_initialize_by(hexdigest: hexdigest)
      attachment.attributes = attrs
      attachment
    end
  end
end
