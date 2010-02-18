require 'stringio'

# this file is pretty crap, its just to ensure there is always something readable if
# there is an rtf only body, with no html encapsulation.

module RTF
	class Tokenizer
		def self.process io
			while true do
				case c = io.getc
				when ?{; yield :open_group
				when ?}; yield :close_group
				when ?\\
					case c = io.getc
					when ?{, ?}, ?\\; yield :text, c.chr
					when ?'; yield :text, [io.read(2)].pack('H*')
					when ?a..?z, ?A..?Z
						# read control word
						str = c.chr
						str << c while c = io.read(1) and c =~ /[a-zA-Z]/
						neg = 1
						neg = -1 and c = io.read(1) if c == '-'
						num = if c =~ /[0-9]/
							num = c
							num << c while c = io.read(1) and c =~ /[0-9]/
							num.to_i * neg
						end
						raise "invalid rtf stream" if neg == -1 and !num # ???? \blahblah- some text
						io.seek(-1, IO::SEEK_CUR) if c != ' '
						yield :control_word, str, num
					when nil
						raise "invalid rtf stream" # \EOF
					else
						# other kind of control symbol
						yield :control_symbol, c.chr
					end
				when nil
					return
				when ?\r, ?\n
					# ignore
				else yield :text, c.chr
				end
			end
		end
	end

	class Converter
		# crappy
		def self.rtf2text str, format=:text
			group = 0
			text = ''
			text << "<html>\n<body>" if format == :html
			group_type = []
			group_tags = []
			RTF::Tokenizer.process(StringIO.new(str)) do |a, b, c|
				add_text = ''
				case a
				when :open_group; group += 1; group_type[group] = nil; group_tags[group] = []
				when :close_group; group_tags[group].reverse.each { |t| text << "</#{t}>" }; group -= 1;
				when :control_word; # ignore
					group_type[group] ||= b
					# maybe change this to use utf8 where possible
					add_text = if b == 'par' || b == 'line' || b == 'page'; "\n"
					elsif b == 'tab' || b == 'cell'; "\t"
					elsif b == 'endash' || b == 'emdash'; "-"
					elsif b == 'emspace' || b == 'enspace' || b == 'qmspace'; " "
					elsif b == 'ldblquote'; '"'
					else ''
					end
					if b == 'b' || b == 'i' and format == :html
						close = c == 0 ? '/' : ''
						text << "<#{close}#{b}>"
						if c == 0
							group_tags[group].delete b
						else
							group_tags[group] << b
						end
					end
					# lot of other ones belong in here.\
=begin
\bullet 	Bullet character.
\lquote 	Left single quotation mark.
\rquote 	Right single quotation mark.
\ldblquote 	Left double quotation mark.
\rdblquote
=end
				when :control_symbol; # ignore
					 group_type[group] ||= b
					add_text = ' ' if b == '~' # non-breakable space
					add_text = '-' if b == '_' # non-breakable hypen
				when :text
					add_text = b if group <= 1 or group_type[group] == 'rtlch' && !group_type[0...group].include?('*')
				end
				if format == :html
					text << add_text.gsub(/([<>&"'])/) do
						ent = { '<' => 'lt', '>' => 'gt', '&' => 'amp', '"' => 'quot', "'" => 'apos' }[$1]
						"&#{ent};"
					end
					text << '<br>' if add_text == "\n"
				else
					text << add_text
				end
			end
			text << "</body>\n</html>\n" if format == :html
			text
		end
	end
end

