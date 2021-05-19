# Everything to do with validating a DraftInfoRequest title
module InfoRequest::DraftTitleValidation
  extend ActiveSupport::Concern

  included do
    validates :title, length: {
      maximum: 200,
      message: _('Please keep the summary short, like in the subject of an ' \
                 'email. You can use a phrase, rather than a full sentence.')
    }
  end
end
