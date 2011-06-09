# Refer from activesupport-2.2.0.
#
# * Remove the dependecies to activesupport.
# * change the key to hash value of args.
# * Not Thread safe
# * Add the clear method.
module Locale
  module Util
    module Memoizable
      MEMOIZED_IVAR = Proc.new do |symbol| 
        "#{symbol.to_s.sub(/\?\Z/, '_query').sub(/!\Z/, '_bang')}".to_sym
      end 

      def self.included(base)
        mod = self
        base.class_eval do
          extend mod
        end
      end

      alias :freeze_without_memoizable :freeze  #:nodoc:
      def freeze #:nodoc:
        unless frozen?
          @_memoized_ivars = {}
          freeze_without_memoizable
        end
      end

      # Clear memoized values. Deprecated.
      def clear  # :nodoc: 
        @_memoized_ivars = {}
      end

      # Clear memoized values.
      def memoize_clear
        @_memoized_ivars = {}
      end

      # Cache the result of the methods.
      #
      #  include Memoizable
      #  def foo
      #    ......
      #  end
      #  def bar(a, b)
      #    ......
      #  end
      #  memoize :foo, :bar(a, b)
      # 
      # To clear cache, #clear_foo, #clear_bar is also defined.
      #
      # (NOTE) 
      # * Consider to use this with huge objects to avoid memory leaks.
      # * Can't use this with super.<method> because of infinity loop.
      def memoize(*symbols)
        memoize_impl(false, *symbols)
      end

      # memoize with dup. A copy object is returned.
      def memoize_dup(*symbols)
        memoize_impl(true, *symbols)
      end

      def memoize_impl(is_dup, *symbols) #:nodoc:
        symbols.each do |symbol|
          original_method = "_unmemoized_#{symbol}"
          memoized_ivar = MEMOIZED_IVAR.call(symbol)
          dup_meth = is_dup ? "_dup" : ""

          class_eval <<-EOS, __FILE__, __LINE__
            alias #{original_method} #{symbol}
            def #{symbol}(*args)
              _memoize#{dup_meth}(:#{memoized_ivar}, args.hash) do
                #{original_method}(*args)
              end
            end
          EOS
        end
      end

      def _memoize(ivar, key) #:nodoc:
        @_memoized_ivars ||= {}
        @_memoized_ivars[ivar] ||= {}

        ret = @_memoized_ivars[ivar][key]
        unless ret
          ret = yield
          ret.freeze
          @_memoized_ivars[ivar][key] = ret 
        end
        ret
      end

      def _memoize_dup(ivar, key) #:nodoc:
        ret = _memoize(ivar, key) do; yield; end
        if ret
          if ret.kind_of? Array
            ret.map{|v| v.dup}.dup
          else
            ret.dup
          end
        else
          nil
        end
      end
    end
  end
end
