require 'benchmark/base'
require 'activesupport'
I18n.backend = I18n::Backend::Simple.new
I18n.load_path = ['benchmark/locale/de.yml']
I18n.locale = :de
puts "ActiveSupport I18n::Backend::Simple :"
results_test{I18n.translate('activerecord.models.car')=='Auto'}