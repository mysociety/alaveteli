class ApplicationMailbox < ActionMailbox::Base
  routing all: :request
end
