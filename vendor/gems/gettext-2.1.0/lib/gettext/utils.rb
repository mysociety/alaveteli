=begin
  utils.rb - Utility functions

  Copyright (C) 2005,2006 Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.
=end

require 'gettext/tools'

warn "'gettext/utils.rb' is deprecated. Use gettext/tools.rb."

module GetText

  alias :create_mofiles_org :create_mofiles #:nodoc:
  alias :update_pofiles_org :update_pofiles #:nodoc:


  # Deprecated. Use gettext/tools instead.
  def create_mofiles(verbose = false,
                     podir = "./po", targetdir = "./data/locale",
                     targetpath_rule = "%s/LC_MESSAGES")  # :nodoc:
    warn "'gettext/utils.rb' is deprecated. Use gettext/tools.rb."
    create_mofiles_org(:verbose => verbose,
                        :po_root => podir,
                        :mo_root => targetdir,
                        :mo_root_rule => targetpath_rule)
  end

  # Deprecated. Use gettext/tools instead.
  def update_pofiles(textdomain, files, app_version, po_root = "po", refpot = "tmp.pot") # :nodoc:
    warn "'gettext/utils.rb' is deprecated. Use gettext/tools.rb."
    options = {:po_root => po_root}
    update_pofiles_org(textdomain, files, app_version, options)
  end
end
