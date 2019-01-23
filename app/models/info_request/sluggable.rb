# A module to generate unique URL title slugs for Info Requests
#
module InfoRequest::Sluggable
  extend ActiveSupport::Concern

  included do
    # make sure the url_title is unique but don't update
    # existing requests unless the title is being changed
    before_save :update_url_title,
                if: proc { |request| request.title_changed? }
  end

  # When title is changed, also change the URL title
  def title=(title)
    super.tap do
      update_url_title
    end
  end

  # Public: url_title attribute reader
  #
  # opts - Hash of options (default: {})
  #        :collapse - Set true to strip the numeric section. Use this to group
  #                    lots of similar requests by url_title.
  #
  # Returns a String
  def url_title(opts = {})
    _url_title = super()
    return _url_title.gsub(/[_0-9]+$/, "") if opts[:collapse]
    _url_title
  end

  private

  def update_url_title
    return unless title

    url_title = MySociety::Format.simplify_url_part(title, 'request', 32)
    suffix = suffix_number(url_title)
    unique_url_title = suffix ? "#{url_title}_#{suffix}" : url_title

    write_attribute(:url_title, unique_url_title)
  end

  def suffix_number(url_title)
    # For request with same title as others, add on arbitrary numeric identifier
    suffixes = existing_url_titles(url_title)
    suffixes.last + 1 if suffixes.present?
  end

  def existing_url_titles(url_title)
    scope =
      if persisted?
        InfoRequest.where.not(id: id)
      else
        InfoRequest
      end

    scope.where('url_title ~ ?', "^#{url_title}(_\\d+)?$").
          pluck(:url_title).
          map { |t| (t[/_(\d+)$/, 1] || 1).to_i }.
          sort
  end
end
