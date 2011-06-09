require 'locale/util/memoizable'

module GetText
  # For normalize/finding the related classes/modules.
  # This is used for realizing the scope of TextDomain.
  # (see: http://www.yotabanana.com/hiki/ruby-gettext-scope.html)
  module ClassInfo
    extend self
    include Locale::Util::Memoizable

    # normalize the class name
    # klass should kind of the class, not object.
    def normalize_class(klass)
      ret = (klass.kind_of? Module) ? klass : klass.class
      if ret.name =~ /^\#<|^$/ or ret == GetText
        ret = Object
      end
      ret
    end

    def root_ancestors  # :nodoc:
      Object.ancestors
    end
    memoize :root_ancestors

    # Internal method for related_classes.
    def related_classes_internal(klass, all_classes = [], analyzed_classes = [] )
      ret = []
      klass = normalize_class(klass)

      return [Object] if root_ancestors.include? klass

      ary = klass.name.split(/::/)
      while(v = ary.shift)
        ret.unshift(((ret.size == 0) ? Object.const_get(v) : ret[0].const_get(v)))
      end
      ret -= analyzed_classes
      if ret.size > 1
        ret += related_classes_internal(ret[1], all_classes, analyzed_classes)
        ret.uniq!
      end
      analyzed_classes << klass unless analyzed_classes.include? klass

      klass.ancestors[1..-1].each do |a|
        ret += related_classes_internal(a, all_classes, analyzed_classes)
        ret.uniq!
      end

      if all_classes.size > 0
        (ret & all_classes).uniq 
      else
        ret.uniq
      end
    end

    # Returns the classes which related to klass 
    # (klass's ancestors, included modules and nested modules)
    def related_classes(klass, all_classes = [])
      ret = related_classes_internal(klass, all_classes)
      unless ret.include? Object
        ret += [Object]
      end
      ret
    end
    memoize :related_classes
  end
end
