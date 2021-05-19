# Everything to do with validating an InfoRequest title
module InfoRequest::TitleValidation
  extend ActiveSupport::Concern
  include InfoRequest::DraftTitleValidation

  included do
    validates_presence_of :title,
                          message: N_('Please enter a summary of your request')

    validates_format_of :title,
      with: /\A.*[[:alpha:]]+.*\z/,
      message: N_('Please write a summary with some text in it'),
      unless: proc { |record| record.title.blank? }

    validates :title, length: {
      minimum: 3,
      message: _('Summary is too short. Please be a little more descriptive ' \
                 'about the information you are asking for.'),
      unless: proc { |record| record.title.blank? },
      on: :create
    }

    # only check on create, so existing models with mixed case are allowed
    validate :title_formatting, on: :create
  end

  private

  def title_formatting
    return unless title
    errors.add(:title, poorly_formed_title_msg) if poorly_formed_title?
    errors.add(:title, generic_foi_title_msg) if generic_foi_title?
  end

  def title_is_acronym(max_length)
    title.upcase == title && title.length <= max_length && !title.include?(' ')
  end

  def title_starts_with_number
    title.include?(' ') && title.split(' ').first =~ /^\d+$/
  end

  def poorly_formed_title?
    !well_formed_title?
  end

  def well_formed_title?
    MySociety::Validate.uses_mixed_capitals(title, 1) ||
      title_starts_with_number ||
      title_is_acronym(6)
  end

  def poorly_formed_title_msg
    _('Please write the summary using a mixture of ' \
      'capital and lower case letters. This makes it ' \
      'easier for others to read.')
  end

  def generic_foi_title?
    title =~ /^(FOI|Freedom of Information)\s*requests?$/i
  end

  def generic_foi_title_msg
    _('Please describe more what the request is about ' \
      'in the subject. There is no need to say it is an ' \
      'FOI request, we add that on anyway.')
  end
end
