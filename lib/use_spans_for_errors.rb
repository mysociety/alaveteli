# -*- encoding : utf-8 -*-
# Monkeypatch! Use SPAN instead of DIV.
#
# Rails core refuse to fix this properly, by making it an official option.
# Without it, you will get HTML validation errors in various places where an
# error appears within a P.
#
# A monkeypatch will have to do.
#
# See http://dev.rubyonrails.org/ticket/2210

ActionView::Base.field_error_proc = Proc.new{ |html_tag, instance|  %(<span class="fieldWithErrors">#{html_tag}</span>).html_safe}
