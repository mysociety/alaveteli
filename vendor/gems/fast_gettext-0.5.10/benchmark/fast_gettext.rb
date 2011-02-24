require 'benchmark/base'

$LOAD_PATH.unshift 'lib'
require 'fast_gettext'
include FastGettext::Translation

FastGettext.available_locales  = ['de','en']
FastGettext.locale = 'de'

puts "FastGettext:"
FastGettext.add_text_domain('test',:path=>locale_folder('test'))
FastGettext.text_domain = 'test'
results_test{_('car') == 'Auto'}

#i cannot add the large file, since its an internal applications mo file
FastGettext.add_text_domain('large',:path=>locale_folder('large'))
FastGettext.text_domain = 'large'
results_large