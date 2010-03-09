require 'yaml'
require 'mapi/types'
require 'mapi/rtf'
require 'rtf'

module Mapi
	#
	# The Mapi::PropertySet class is used to wrap the lower level Msg or Pst property stores,
	# and provide a consistent and more friendly interface. It allows you to just say:
	#
	#   properties.subject
	#
	# instead of:
	#
	#   properites.raw[0x0037, PS_MAPI]
	#
	# The underlying store can be just a hash, or lazily loading directly from the file. A good
	# compromise is to cache all the available keys, and just return the values on demand, rather
	# than load up many possibly unwanted values.
	#
	class PropertySet
		# the property set guid constants
		# these guids are all defined with the macro DEFINE_OLEGUID in mapiguid.h.
		# see http://doc.ddart.net/msdn/header/include/mapiguid.h.html
		oleguid = proc do |prefix|
			Ole::Types::Clsid.parse "{#{prefix}-0000-0000-c000-000000000046}"
		end

		NAMES = {
			oleguid['00020328'] => 'PS_MAPI',
			oleguid['00020329'] => 'PS_PUBLIC_STRINGS',
			oleguid['00020380'] => 'PS_ROUTING_EMAIL_ADDRESSES',
			oleguid['00020381'] => 'PS_ROUTING_ADDRTYPE',
			oleguid['00020382'] => 'PS_ROUTING_DISPLAY_NAME',
			oleguid['00020383'] => 'PS_ROUTING_ENTRYID',
			oleguid['00020384'] => 'PS_ROUTING_SEARCH_KEY',
			# string properties in this namespace automatically get added to the internet headers
			oleguid['00020386'] => 'PS_INTERNET_HEADERS',
			# theres are bunch of outlook ones i think
			# http://blogs.msdn.com/stephen_griffin/archive/2006/05/10/outlook-2007-beta-documentation-notification-based-indexing-support.aspx
			# IPM.Appointment
			oleguid['00062002'] => 'PSETID_Appointment',
			# IPM.Task
			oleguid['00062003'] => 'PSETID_Task',
			# used for IPM.Contact
			oleguid['00062004'] => 'PSETID_Address',
			oleguid['00062008'] => 'PSETID_Common',
			# didn't find a source for this name. it is for IPM.StickyNote
			oleguid['0006200e'] => 'PSETID_Note',
			# for IPM.Activity. also called the journal?
			oleguid['0006200a'] => 'PSETID_Log',
		}

		module Constants
			NAMES.each { |guid, name| const_set name, guid }
		end

		include Constants

		# +Properties+ are accessed by <tt>Key</tt>s, which are coerced to this class.
		# Includes a bunch of methods (hash, ==, eql?) to allow it to work as a key in
		# a +Hash+.
		#
		# Also contains the code that maps keys to symbolic names.
		class Key
			include Constants

			attr_reader :code, :guid
			def initialize code, guid=PS_MAPI
				@code, @guid = code, guid
			end

			def to_sym
				# hmmm, for some stuff, like, eg, the message class specific range, sym-ification
				# of the key depends on knowing our message class. i don't want to store anything else
				# here though, so if that kind of thing is needed, it can be passed to this function.
				# worry about that when some examples arise.
				case code
				when Integer
					if guid == PS_MAPI # and < 0x8000 ?
						# the hash should be updated now that i've changed the process
						TAGS['%04x' % code].first[/_(.*)/, 1].downcase.to_sym rescue code
					else
						# handle other guids here, like mapping names to outlook properties, based on the
						# outlook object model.
						NAMED_MAP[self].to_sym rescue code
					end
				when String
					# return something like
					# note that named properties don't go through the map at the moment. so #categories
					# doesn't work yet
					code.downcase.to_sym
				end
			end
			
			def to_s
				to_sym.to_s
			end

			# FIXME implement these
			def transmittable?
				# etc, can go here too
			end

			# this stuff is to allow it to be a useful key
			def hash
				[code, guid].hash
			end

			def == other
				hash == other.hash
			end

			alias eql? :==

			def inspect
				# maybe the way to do this, would be to be able to register guids
				# in a global lookup, which are used by Clsid#inspect itself, to
				# provide symbolic names...
				guid_str = NAMES[guid] || "{#{guid.format}}" rescue "nil"
				if Integer === code
					hex = '0x%04x' % code
					if guid == PS_MAPI
						# just display as plain hex number
						hex
					else
						"#<Key #{guid_str}/#{hex}>"
					end
				else
					# display full guid and code
					"#<Key #{guid_str}/#{code.inspect}>"
				end
			end
		end

		# duplicated here for now
		SUPPORT_DIR = File.dirname(__FILE__) + '/../..'

		# data files that provide for the code to symbolic name mapping
		# guids in named_map are really constant references to the above
		TAGS = YAML.load_file "#{SUPPORT_DIR}/data/mapitags.yaml"
		NAMED_MAP = YAML.load_file("#{SUPPORT_DIR}/data/named_map.yaml").inject({}) do |hash, (key, value)|
			hash.update Key.new(key[0], const_get(key[1])) => value
		end

		attr_reader :raw
	
		# +raw+ should be an hash-like object that maps <tt>Key</tt>s to values. Should respond_to?
		# [], keys, values, each, and optionally []=, and delete.
		def initialize raw
			@raw = raw
		end

		# resolve +arg+ (could be key, code, string, or symbol), and possible +guid+ to a key.
		# returns nil on failure
		def resolve arg, guid=nil
			if guid;        Key.new arg, guid
			else
				case arg
				when Key;     arg
				when Integer; Key.new arg
				else          sym_to_key[arg.to_sym]
				end
			end
		end

		# this is the function that creates a symbol to key mapping. currently this works by making a
		# pass through the raw properties, but conceivably you could map symbols to keys using the
		# mapitags directly. problem with that would be that named properties wouldn't map automatically,
		# but maybe thats not too important.
		def sym_to_key
			return @sym_to_key if @sym_to_key
			@sym_to_key = {}
			raw.keys.each do |key|
				sym = key.to_sym
				unless Symbol === sym
					Log.debug "couldn't find symbolic name for key #{key.inspect}" 
					next
				end
				if @sym_to_key[sym]
					Log.warn "duplicate key #{key.inspect}"
					# we give preference to PS_MAPI keys
					@sym_to_key[sym] = key if key.guid == PS_MAPI
				else
					# just assign
					@sym_to_key[sym] = key
				end
			end
			@sym_to_key
		end

		def keys
			sym_to_key.keys
		end
		
		def values
			sym_to_key.values.map { |key| raw[key] }
		end

		def [] arg, guid=nil
			raw[resolve(arg, guid)]
		end

		def []= arg, *args
			args.unshift nil if args.length == 1
			guid, value = args
			# FIXME this won't really work properly. it would need to go
			# to TAGS to resolve, as it often won't be there already...
			raw[resolve(arg, guid)] = value
		end

		def method_missing name, *args
			if name.to_s !~ /\=$/ and args.empty?
				self[name]
			elsif name.to_s =~ /(.*)\=$/ and args.length == 1
				self[$1] = args[0]
			else
				super
			end
		end

		def to_h
			sym_to_key.inject({}) { |hash, (sym, key)| hash.update sym => raw[key] }
		end

		def inspect
			"#<#{self.class} " + to_h.sort_by { |k, v| k.to_s }.map do |k, v|
				v = v.inspect
				"#{k}=#{v.length > 32 ? v[0..29] + '..."' : v}"
			end.join(' ') + '>'
		end

		# -----
		
		# temporary pseudo tags
		
		# for providing rtf to plain text conversion. later, html to text too.
		def body
			return @body if defined?(@body)
			@body = (self[:body] rescue nil)
			# last resort
			if !@body or @body.strip.empty?
				Log.warn 'creating text body from rtf'
				@body = (::RTF::Converter.rtf2text body_rtf rescue nil)
			end
			@body
		end

		# for providing rtf decompression
		def body_rtf
			return @body_rtf if defined?(@body_rtf)
			@body_rtf = (RTF.rtfdecompr rtf_compressed.read rescue nil)
		end

		# for providing rtf to html conversion
		def body_html
			return @body_html if defined?(@body_html)
			@body_html = (self[:body_html].read rescue nil)
			@body_html = (RTF.rtf2html body_rtf rescue nil) if !@body_html or @body_html.strip.empty?
			# last resort
			if !@body_html or @body_html.strip.empty?
				Log.warn 'creating html body from rtf'
				@body_html = (::RTF::Converter.rtf2text body_rtf, :html rescue nil)
			end
			@body_html
		end
	end
end

