##
# Controller to serve FoiAttachment records in both raw and as HTML.
#
class AttachmentsController < ApplicationController
  include FragmentCachable

  before_action :find_info_request, :find_incoming_message
  before_action :authenticate_attachment
  around_action :cache_attachments

  def show
    get_attachment_internal(false)
    return unless @attachment

    # we don't use @attachment.content_type here, as we want same mime type
    # when cached in cache_attachments above
    content_type =
      AlaveteliFileTypes.filename_to_mimetype(params[:file_name]) ||
      'application/octet-stream'

    # Prevent spam to magic request address. Note that the binary
    # subsitution method used depends on the content type
    body = @incoming_message.apply_masks(
      @attachment.default_body,
      @attachment.content_type
    )

    if content_type == 'text/html'
      body =
        Loofah.scrub_document(body, :prune).
        to_html(encoding: 'UTF-8').
        try(:html_safe)
    end

    render body: body, content_type: content_type
  end

  def show_as_html
    # The conversion process can generate files in the cache directory that can
    # be served up directly by the webserver according to httpd.conf, so don't
    # allow it unless that's OK.
    if @files_can_be_cached != true
      raise ActiveRecord::RecordNotFound, 'Attachment HTML not found.'
    end
    get_attachment_internal(true)
    return unless @attachment

    # images made during conversion (e.g. images in PDF files) are put in the
    # cache directory, so the same cache code in cache_attachments above will
    # display them.
    key = params.merge(only_path: true)
    key_path = foi_fragment_cache_path(key)
    image_dir = File.dirname(key_path)
    FileUtils.mkdir_p(image_dir)

    html = @attachment.body_as_html(
      image_dir,
      attachment_url: Rack::Utils.escape(@attachment_url),
      content_for: {
        head_suffix: render_to_string(
          partial: 'request/view_html_stylesheet',
          formats: [:html]
        ),
        body_prefix: render_to_string(
          partial: 'request/view_html_prefix'
        )
      }
    )

    html = @incoming_message.apply_masks(html, response.content_type)

    render html: html.html_safe
  end

  private

  def find_info_request
    @info_request = InfoRequest.find(params[:id])
  end

  def find_incoming_message
    @incoming_message = @info_request.incoming_messages.find(
      params[:incoming_message_id]
    )
  end

  def authenticate_attachment
    # Test for hidden
    if @incoming_message.nil?
      raise ActiveRecord::RecordNotFound, "Message not found"
    end
    if cannot?(:read, @info_request)
      request.format = :html
      return render_hidden
    end
    if cannot?(:read, @incoming_message)
      request.format = :html
      return render_hidden('request/hidden_correspondence')
    end
    # Is this a completely public request that we can cache attachments for
    # to be served up without authentication?
    if @incoming_message.info_request.prominence(decorate: true).is_public? &&
       @incoming_message.is_public?
      @files_can_be_cached = true
    end
  end

  # special caching code so mime types are handled right
  def cache_attachments
    if !params[:skip_cache].nil?
      yield
    else
      key = params.merge(only_path: true)
      key_path = foi_fragment_cache_path(key)
      if foi_fragment_cache_exists?(key_path)
        logger.info("Reading cache for #{key_path}")

        if File.directory?(key_path)
          render plain: 'Directory listing not allowed', status: 403
        else
          content_type =
            AlaveteliFileTypes.filename_to_mimetype(params[:file_name]) ||
            'application/octet-stream'

          render body: foi_fragment_cache_read(key_path),
                 content_type: content_type
        end
        return
      end

      yield

      if params[:skip_cache].nil? && response.status == 200
        # write it to the fileystem ourselves, so is just a plain file. (The
        # various fragment cache functions using Ruby Marshall to write the file
        # which adds a header, so isnt compatible with images that have been
        # extracted elsewhere from PDFs)
        if @files_can_be_cached == true
          logger.info("Writing cache for #{key_path}")
          foi_fragment_cache_write(key_path, response.body)
        end
      end
    end
  end

  def get_attachment_internal(html_conversion)
    @incoming_message.parse_raw_email!
    if @incoming_message.info_request_id != params[:id].to_i
      # Note that params[:id] might not be an integer, though
      # if we’ve got this far then it must begin with an integer
      # and that integer must be the id number of an actual request.
      message = format("Incoming message %d does not belong to request '%s'",
                       @incoming_message.info_request_id, params[:id])
      raise ActiveRecord::RecordNotFound, message
    end
    @part_number = params[:part].to_i
    @filename = params[:file_name]
    if html_conversion
      @original_filename = @filename.gsub(/\.html$/, '')
    else
      @original_filename = @filename
    end

    # check permissions
    if cannot?(:read, @info_request)
      raise "internal error, pre-auth filter should have caught this"
    end
    @attachment = IncomingMessage.
      get_attachment_by_url_part_number_and_filename(
        @incoming_message.get_attachments_for_display,
        @part_number,
        @original_filename
      )
    # If we can't find the right attachment, redirect to the incoming message:
    unless @attachment
      return redirect_to incoming_message_url(@incoming_message), status: 303
    end

    # check filename in URL matches that in database (use a censor rule if you
    # want to change a filename)
    if @attachment.display_filename != @original_filename &&
       @attachment.old_display_filename != @original_filename
      msg = 'please use same filename as original file has, display: '
      msg += "'#{ @attachment.display_filename }' "
      msg += 'old_display: '
      msg += "'#{ @attachment.old_display_filename }' "
      msg += 'original: '
      msg += "'#{ @original_filename }'"
      raise ActiveRecord::RecordNotFound, msg
    end

    @attachment_url = get_attachment_url(
      id: @incoming_message.info_request_id,
      incoming_message_id: @incoming_message.id,
      part: @part_number,
      file_name: @original_filename
    )
  end
end
