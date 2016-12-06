class RequestFilter

  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :filter, :order, :search

  def update_attributes(attributes = {})
    self.attributes = attributes
  end

  def attributes=(attributes)
    self.filter = attributes[:filter] unless attributes[:filter].blank?
    self.order = attributes[:order]
    self.search = attributes[:search]
  end

  def order_options
    order_attributes.map { |atts| [atts[:label], atts[:param]] }
  end

  def filter_label
    filter_params.include?(@filter) ? filter_labels[@filter] : nil
  end

  def results(user)
    if filter == 'draft'
      info_requests = user.draft_info_requests
    else
      info_requests = user.info_requests
    end
    if !filter_value.blank?
      info_requests = info_requests.send(filter_value)
    end
    if search
      info_requests = info_requests.where("title ILIKE :q", q: "%#{ search }%")
    end
    info_requests.reorder(order_value)
  end

  def persisted?
    false
  end

  private

  def order_attributes
    [
     { :param => 'updated_at_desc',
       :value => 'updated_at DESC',
       :label => _('Last updated') },
     { :param => 'created_at_asc',
       :value => 'created_at ASC',
       :label => _('First created') },
     { :param => 'title_asc',
       :value => 'title ASC',
       :label => _('Title (A-Z)') }
    ]
  end

  def order_params
    order_attributes.map{ |atts| atts[:param] }
  end

  def order_values
    Hash[order_attributes.map{ |atts| [ atts[:param], atts[:value] ] }]
  end

  def order_value
    order_params.include?(@order) ? order_values[@order] : default_order
  end

  def default_order
    'updated_at DESC'
  end

  def default_filters
    [ { :param => nil,
        :value => nil,
        :label => _('All requests') },
      { :param => 'draft',
        :value => nil,
        :label => _('Drafts') },
     ]
  end

  def phase_filters
    InfoRequest::State.phases.map{ |phase| { :param => phase[:scope].to_s,
                                             :value => phase[:scope],
                                             :label => phase[:name] }  }
  end

  def filter_attributes
    default_filters + phase_filters
  end

  def filter_options
    filter_attributes.map {|atts| [atts[:label], atts[:param]] }
  end

  def filter_labels
    Hash[ filter_options ].invert
  end

  def filter_params
    filter_attributes.map{ |atts| atts[:param] }
  end

  def filter_values
    Hash[ filter_attributes.map{ |atts| [ atts[:param], atts[:value] ] } ]
  end

  def filter_value
    filter_params.include?(@filter) ? filter_values[@filter] : nil
  end

end
