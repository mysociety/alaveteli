require 'zip'

# Manually set `validate_entry_sizes`, which is the default in rubyzip 2.0.0.
# rubyzip 2.0.0 requires Ruby 2.4+, so we can't upgrade to that yet.
#
# See: https://github.com/rubyzip/rubyzip/pull/403
Zip.validate_entry_sizes = true
