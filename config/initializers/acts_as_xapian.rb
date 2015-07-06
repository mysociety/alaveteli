# -*- encoding : utf-8 -*-
# acts_as_xapian/init.rb:
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

# We're moving plugins out of vendor/plugins, since keeping them there
# is deprecated as of Rails 3.2, and the xapiandbs directory should be
# moved out of there along with the plugin itself.

old_xapiandbs_path = Rails.root.join('vendor',
                                     'plugins',
                                     'acts_as_xapian',
                                     'xapiandbs')

current_xapiandbs_path = Rails.root.join('lib',
                                         'acts_as_xapian',
                                         'xapiandbs')

if File.exists? old_xapiandbs_path
    unless File.exists? current_xapiandbs_path
        File.rename old_xapiandbs_path, current_xapiandbs_path
    end
end

require 'acts_as_xapian/acts_as_xapian'
