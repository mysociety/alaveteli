#
# = Introduction
#
# A *basic* mime class for _really_ _basic_ and probably non-standard parsing
# and construction of MIME messages.
#
# Intended for two main purposes in this project:
# 1. As the container that is used to build up the message for eventual
#    serialization as an eml.
# 2. For assistance in parsing the +transport_message_headers+ provided in .msg files,
#    which are then kept through to the final eml.
#
# = TODO
#
# * Better streaming support, rather than an all-in-string approach.
# * Add +OrderedHash+ optionally, to not lose ordering in headers.
# * A fair bit remains to be done for this class, its fairly immature. But generally I'd like
#   to see it be more generally useful.
# * All sorts of correctness issues, encoding particular.
# * Duplication of work in net/http.rb's +HTTPHeader+? Don't know if the overlap is sufficient.
#   I don't want to lower case things, just for starters.
# * Mime was the original place I wrote #to_tree, intended as a quick debug hack.
#
class SimpleMime
	Hash = begin
		require 'orderedhash'
		OrderedHash
	rescue LoadError
		Hash
	end

	attr_reader :headers, :body, :parts, :content_type, :preamble, :epilogue

	# Create a SimpleMime object using +str+ as an initial serialization, which must contain headers
	# and a body (even if empty). Needs work.
	def initialize str, ignore_body=false
		headers, @body = $~[1..-1] if str[/(.*?\r?\n)(?:\r?\n(.*))?\Z/m]

		@headers = Hash.new { |hash, key| hash[key] = [] }
		@body ||= ''
		headers.to_s.scan(/^\S+:\s*.*(?:\n\t.*)*/).each do |header|
			@headers[header[/(\S+):/, 1]] << header[/\S+:\s*(.*)/m, 1].gsub(/\s+/m, ' ').strip # this is kind of wrong
		end

		# don't have to have content type i suppose
		@content_type, attrs = nil, {}
		if content_type = @headers['Content-Type'][0]
			@content_type, attrs = SimpleMime.split_header content_type
		end

		return if ignore_body

		if multipart?
			if body.empty?
				@preamble = ''
				@epilogue = ''
				@parts = []
			else
				# we need to split the message at the boundary
				boundary = attrs['boundary'] or raise "no boundary for multipart message"

				# splitting the body:
				parts = body.split(/--#{Regexp.quote boundary}/m)
				unless parts[-1] =~ /^--/; warn "bad multipart boundary (missing trailing --)"
				else parts[-1][0..1] = ''
				end
				parts.each_with_index do |part, i|
					part =~ /^(\r?\n)?(.*?)(\r?\n)?\Z/m
					part.replace $2
					warn "bad multipart boundary" if (1...parts.length-1) === i and !($1 && $3)
				end
				@preamble = parts.shift
				@epilogue = parts.pop
				@parts = parts.map { |part| SimpleMime.new part }
			end
		end
	end

	def multipart?
		@content_type && @content_type =~ /^multipart/ ? true : false
	end

	def inspect
		# add some extra here.
		"#<SimpleMime content_type=#{@content_type.inspect}>"
	end

	def to_tree
		if multipart?
			str = "- #{inspect}\n"
			parts.each_with_index do |part, i|
				last = i == parts.length - 1
				part.to_tree.split(/\n/).each_with_index do |line, j|
					str << "  #{last ? (j == 0 ? "\\" : ' ') : '|'}" + line + "\n"
				end
			end
			str
		else
			"- #{inspect}\n"
		end
	end

	def to_s opts={}
		opts = {:boundary_counter => 0}.merge opts
		if multipart?
			boundary = SimpleMime.make_boundary opts[:boundary_counter] += 1, self
			@body = [preamble, parts.map { |part| "\r\n" + part.to_s(opts) + "\r\n" }, "--\r\n" + epilogue].
				flatten.join("\r\n--" + boundary)
			content_type, attrs = SimpleMime.split_header @headers['Content-Type'][0]
			attrs['boundary'] = boundary
			@headers['Content-Type'] = [([content_type] + attrs.map { |key, val| %{#{key}="#{val}"} }).join('; ')]
		end

		str = ''
		@headers.each do |key, vals|
			vals.each { |val| str << "#{key}: #{val}\r\n" }
		end
		str << "\r\n" + @body
	end

	def self.split_header header
		# FIXME: haven't read standard. not sure what its supposed to do with " in the name, or if other
		# escapes are allowed. can't test on windows as " isn't allowed anyway. can be fixed with more
		# accurate parser later.
		# maybe move to some sort of Header class. but not all headers should be of it i suppose.
		# at least add a join_header then, taking name and {}. for use in SimpleMime#to_s (for boundary
		# rewrite), and Attachment#to_mime, among others...
		attrs = {}
		header.scan(/;\s*([^\s=]+)\s*=\s*("[^"]*"|[^\s;]*)\s*/m).each do |key, value|
			if attrs[key]; warn "ignoring duplicate header attribute #{key.inspect}"
			else attrs[key] = value[/^"/] ? value[1..-2] : value
			end
		end

		[header[/^[^;]+/].strip, attrs]
	end

	# +i+ is some value that should be unique for all multipart boundaries for a given message
	def self.make_boundary i, extra_obj = SimpleMime
		"----_=_NextPart_#{'%03d' % i}_#{'%08x' % extra_obj.object_id}.#{'%08x' % Time.now}"
	end
end

=begin
things to consider for header work.
encoded words:
Subject: =?iso-8859-1?q?p=F6stal?=

and other mime funkyness:
Content-Disposition: attachment;
	filename*0*=UTF-8''09%20%D7%90%D7%A5;
	filename*1*=%20%D7%A1%D7%91-;
	filename*2*=%D7%A7%95%A5.wma
Content-Transfer-Encoding: base64

and another, doing a test with an embedded newline in an attachment name, I
get this output from evolution. I get the feeling that this is probably a bug
with their implementation though, they weren't expecting new lines in filenames.
Content-Disposition: attachment; filename="asdf'b\"c
d   efgh=i: ;\\j"
d   efgh=i: ;\\j"; charset=us-ascii
Content-Type: text/plain; name="asdf'b\"c"; charset=us-ascii

=end

