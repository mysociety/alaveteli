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

  # When name is changed, also change the url name
  def title=(title)
    write_attribute(:title, title)
    update_url_title
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

  def update_url_title
    return unless title
    url_title = MySociety::Format.simplify_url_part(title, 'request', 32)
    conditions = id ? ["id <> ?", id] : []

    existing_url_titles = InfoRequest.
      where(conditions).
      where('url_title ~ ?', "^#{url_title}(_\\d+)?$").
      pluck(:url_title)

    if existing_url_titles.empty?
      unique_url_title = url_title
    else
      # For request with same title as others, add on arbitrary numeric
      # identifier
      suffix_num = existing_url_titles.map { |t| (t[/_(\d+)$/, 1] || 1).to_i }.
                                       sort.
                                       last + 1
      unique_url_title = "#{url_title}_#{suffix_num}"
    end

    write_attribute(:url_title, unique_url_title)
  end
end
