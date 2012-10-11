# For Rails 2.3 on Ruby 1.9.3 @see https://github.com/rails/rails/pull/3745
MissingSourceFile::REGEXPS << [/^cannot load such file -- (.+)$/i, 1]
