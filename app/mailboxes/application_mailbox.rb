##
# Routes inbound email to the mailbox that handles it.
#
class ApplicationMailbox < ActionMailbox::Base
  around_processing :use_default_locale

  routing all: :request

  private

  def use_default_locale(&block)
    AlaveteliLocalization.with_default_locale(&block)
  end
end
