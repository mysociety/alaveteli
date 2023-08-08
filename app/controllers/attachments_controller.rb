##
# Controller to serve FoiAttachment records in both raw and as HTML.
#
class AttachmentsController < ApplicationController
  include FragmentCachable
  include InfoRequestHelper
  include PublicTokenable

  skip_before_action :html_response

  before_action :find_info_request, :find_incoming_message, :find_attachment
  before_action :find_project

  include ProminenceHeaders

  before_action :authenticate_attachment
  before_action :authenticate_attachment_as_html, only: :show_as_html

  around_action :cache_attachments, only: :show_as_html

  def show
    if @attachment.masked?
      render body: @attachment.body, content_type: content_type
    else
      FoiAttachmentMaskJob.perform_later(@attachment)

      Timeout.timeout(5) do
        until @attachment.masked?
          sleep 0.5
          @attachment.reload
        end
        redirect_to(request.fullpath)
      end
    end

  rescue Timeout::Error
    redirect_to wait_for_attachment_mask_path(
      @attachment.to_signed_global_id,
      referer: request.fullpath
    )
  end

  def show_as_html
    # images made during conversion (e.g. images in PDF files) are put in the
    # cache directory, so the same cache code in cache_attachments above will
    # display them.
    image_dir = File.dirname(cache_key_path)
    FileUtils.mkdir_p(image_dir)

    html = @attachment.body_as_html(
      image_dir,
      attachment_url: Rack::Utils.escape(attachment_url(@attachment)),
      content_for: {
        head_suffix: render_to_string(
          partial: 'request/view_html_stylesheet',
          formats: [:html]
        ),
        body_prefix: render_to_string(
          partial: 'request/view_html_prefix',
          formats: [:html]
        )
      }
    )

    html = @incoming_message.apply_masks(html, response.media_type)

    render html: html.html_safe
  end

  private

  def find_info_request
    @info_request =
      if public_token?
        InfoRequest.find_by!(public_token: public_token)
      else
        InfoRequest.find(params[:id])
      end
  end

  def find_incoming_message
    @incoming_message = @info_request.incoming_messages.find(
      params[:incoming_message_id]
    )
  end

  def find_attachment
    @attachment = (
      @incoming_message.parse_raw_email!

      IncomingMessage.get_attachment_by_url_part_number_and_filename!(
        @incoming_message.get_attachments_for_display,
        part_number,
        original_filename
      )
    )
  end

  def find_project
    return unless current_user && params[:project_id]

    @project = current_user.projects.find_by(id: params[:project_id])
  end

  def authenticate_attachment
    # Test for hidden
    if cannot?(:read, @info_request)
      request.format = :html
      return render_hidden
    end
    if cannot?(:read, @incoming_message)
      request.format = :html
      return render_hidden('request/hidden_correspondence')
    end

    if @attachment
      if cannot?(:read, @attachment)
        request.format = :html
        render_hidden('request/hidden_attachment')
      end
    elsif params[:file_name]
      # If we can't find the right attachment, redirect to the incoming message:
      redirect_to incoming_message_url(@incoming_message), status: 303
    else
      render plain: 'Directory listing not allowed', status: 403
    end
  end

  def authenticate_attachment_as_html
    # The conversion process can generate files in the cache directory that can
    # be served up directly by the webserver according to httpd.conf, so don't
    # allow it unless that's OK.
    return if attachment_is_public?

    raise ActiveRecord::RecordNotFound, 'Attachment HTML not found.'
  end

  # special caching code so mime types are handled right
  def cache_attachments
    if !params[:skip_cache].nil?
      yield
    else
      if foi_fragment_cache_exists?(cache_key_path)
        logger.info("Reading cache for #{cache_key_path}")

        render body: foi_fragment_cache_read(cache_key_path),
               content_type: content_type
        return
      end

      yield

      if params[:skip_cache].nil? && response.status == 200
        # write it to the filesystem ourselves, so is just a plain file. (The
        # various fragment cache functions using Ruby Marshall to write the file
        # which adds a header, so isn't compatible with images that have been
        # extracted elsewhere from PDFs)
        if attachment_is_cacheable?
          logger.info("Writing cache for #{cache_key_path}")
          foi_fragment_cache_write(cache_key_path, response.body)
        end
      end
    end
  end

  def part_number
    params[:part].to_i
  end

  def original_filename
    filename = params[:file_name]
    return unless filename

    if action_name == 'show_as_html'
      filename.gsub(/\.html$/, '')
    else
      filename
    end
  end

  def content_type
    # we don't use @attachment.content_type here, as we want same mime type
    # when cached in cache_attachments above
    AlaveteliFileTypes.filename_to_mimetype(params[:file_name]) ||
      'application/octet-stream'
  end

  def attachment_is_public?
    # If this a request, message and attachment are public then it can be served
    # up without authentication
    prominence.is_public? &&
      @incoming_message.is_public? &&
      @attachment.is_public?
  end

  def attachment_is_cacheable?
    # If this a request, message and attachment are searchable then we can cache
    # as there are no custom response headers (EG X-Robots-Tag)
    prominence.is_searchable? &&
      @incoming_message.indexed_by_search? &&
      @attachment.indexed_by_search?
  end

  def cache_key_path
    foi_fragment_cache_path(
      id: @info_request.id,
      incoming_message_id: @incoming_message.id,
      part: part_number,
      file_name: original_filename,
      locale: false
    )
  end

  def current_ability
    @current_ability ||= Ability.new(
      current_user, project: @project, public_token: public_token?
    )
  end

  def prominence
    @info_request.prominence(decorate: true)
  end

  def with_prominence
    @info_request
  end
end
