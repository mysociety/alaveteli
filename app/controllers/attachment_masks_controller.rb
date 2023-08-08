##
# Controller to process FoiAttachment objects before being served publicly by
# applying masks and censor rules.
#
class AttachmentMasksController < ApplicationController
  before_action :set_no_crawl_headers
  before_action :find_attachment
  before_action :ensure_attachment, :ensure_referer

  def wait
    if @attachment.masked?
      redirect_to done_attachment_mask_path(
        id: @attachment.to_signed_global_id,
        referer: params[:referer]
      )

    else
      FoiAttachmentMaskJob.perform_later(@attachment)
    end
  end

  def done
    unless @attachment.masked?
      redirect_to wait_for_attachment_mask_path(
        id: @attachment.to_signed_global_id,
        referer: params[:referer]
      )
    end

    @show_attachment_path = params[:referer]
  end

  private

  def set_no_crawl_headers
    headers['X-Robots-Tag'] = 'noindex'
  end

  def find_attachment
    @attachment = GlobalID::Locator.locate_signed(params[:id])
  end

  def ensure_attachment
    raise ActiveRecord::RecordNotFound unless @attachment
  end

  def ensure_referer
    raise RouteNotFound unless params[:referer].present?
  end
end
