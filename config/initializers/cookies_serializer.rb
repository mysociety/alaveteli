# -*- encoding : utf-8 -*-
# Set the cookie serializer to :hybrid to migrate the old format Marshalled
# cookies to the new, more secure, JSON format
Rails.application.config.action_dispatch.cookies_serializer = :hybrid
