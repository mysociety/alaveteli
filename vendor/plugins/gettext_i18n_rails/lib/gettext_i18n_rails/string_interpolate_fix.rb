needed = "".respond_to?(:html_safe) and
  (
    "".html_safe % {:x => '<br/>'} == '<br/>' or
    not ("".html_safe % {:x=>'a'}).html_safe?
  )

if needed
  class String
    alias :interpolate_without_html_safe :%

    def %(*args)
      if args.first.is_a?(Hash) and html_safe?
        safe_replacement = Hash[args.first.map{|k,v| [k,ERB::Util.h(v)] }]
        interpolate_without_html_safe(safe_replacement).html_safe
      else
        interpolate_without_html_safe(*args).dup # make sure its not html_safe
      end
    end
  end
end