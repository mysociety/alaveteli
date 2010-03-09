require 'rubygems'
require 'ole/storage'
require 'mapi'
require 'mapi/rtf'

module Mapi
	#
	# = Introduction
	#
	# Primary class interface to the vagaries of .msg files.
	#
	# The core of the work is done by the <tt>Msg::PropertyStore</tt> class.
	#
	class Msg < Message
		#
		# = Introduction
		#
		# A big compononent of +Msg+ files is the property store, which holds
		# all the key/value pairs of properties. The message itself, and all
		# its <tt>Attachment</tt>s and <tt>Recipient</tt>s have an instance of
		# this class.
		#
		# = Storage model
		#
		# Property keys (tags?) can be either simple hex numbers, in the
		# range 0x0000 - 0xffff, or they can be named properties. In fact,
		# properties in the range 0x0000 to 0x7fff are supposed to be the non-
		# named properties, and can be considered to be in the +PS_MAPI+
		# namespace. (correct?)
		# 
		# Named properties are serialized in the 0x8000 to 0xffff range,
		# and are referenced as a guid and long/string pair.
		#
		# There are key ranges, which can be used to imply things generally
		# about keys.
		#
		# Further, we can give symbolic names to most keys, coming from
		# constants in various places. Eg:
		# 
		#   0x0037 => subject
		#   {00062002-0000-0000-C000-000000000046}/0x8218 => response_status
		#   # displayed as categories in outlook
		#   {00020329-0000-0000-C000-000000000046}/"Keywords" => categories
		# 
		# Futher, there are completely different names, coming from other
		# object models that get mapped to these things (CDO's model,
		# Outlook's model etc). Eg "urn:schemas:httpmail:subject"
		# I think these can be ignored though, as they aren't defined clearly
		# in terms of mapi properties, and i'm really just trying to make
		# a mapi property store. (It should also be relatively easy to
		# support them later.)
		# 
		# = Usage
		#
		# The api is driven by a desire to have the simple stuff "just work", ie
		#
		#   properties.subject
		#   properties.display_name
		# 
		# There also needs to be a way to look up properties more specifically:
		# 
		#   properties[0x0037] # => gets the subject
		#   properties[0x0037, PS_MAPI] # => still gets the subject
		#   properties['Keywords', PS_PUBLIC_STRINGS] # => gets outlook's categories array
		# 
		# The abbreviated versions work by "resolving" the symbols to full keys:
		#
		#		# the guid here is just PS_PUBLIC_STRINGS
		#   properties.resolve :keywords # => #<Key {00020329-0000-0000-c000-000000000046}/"Keywords">
		#   # the result here is actually also a key
		#   k = properties.resolve :subject  # => 0x0037
		#   # it has a guid
		#   k.guid == Msg::Properties::PS_MAPI # => true
		#
		# = Parsing
		#
		# There are three objects that need to be parsed to load a +Msg+ property store:
		# 
		# 1. The +nameid+ directory (<tt>Properties.parse_nameid</tt>)
		# 2. The many +substg+ objects, whose names should match <tt>Properties::SUBSTG_RX</tt>
		#    (<tt>Properties#parse_substg</tt>)
		# 3. The +properties+ file (<tt>Properties#parse_properties</tt>)
		#
		# Understanding of the formats is by no means perfect.
		#
		# = TODO
		#
		# * While the key objects are sufficient, the value objects are just plain
		#   ruby types. It currently isn't possible to write to the values, or to know
		#   which encoding the value had.
		# * Update this doc.
		# * Perhaps change from eager loading, to be load-on-demand.
		#
		class PropertyStore
			include PropertySet::Constants
			Key = PropertySet::Key

			# note that binary and default both use obj.open. not the block form. this means we should
			# #close it later, which we don't. as we're only reading though, it shouldn't matter right?
			# not really good though FIXME
			# change these to use mapi symbolic const names
			ENCODINGS = {
				0x000d =>   proc { |obj| obj }, # seems to be used when its going to be a directory instead of a file. eg nested ole. 3701 usually. in which case we shouldn't get here right?
				0x001f =>   proc { |obj| Ole::Types::FROM_UTF16.iconv obj.read }, # unicode
				# ascii
				# FIXME hack did a[0..-2] before, seems right sometimes, but for some others it chopped the text. chomp
				0x001e =>   proc { |obj| obj.read.chomp 0.chr },
				0x0102 =>   proc { |obj| obj.open }, # binary?
				:default => proc { |obj| obj.open }
			}

			SUBSTG_RX = /^__substg1\.0_([0-9A-F]{4})([0-9A-F]{4})(?:-([0-9A-F]{8}))?$/
			PROPERTIES_RX = /^__properties_version1\.0$/
			NAMEID_RX = /^__nameid_version1\.0$/
			VALID_RX = /#{SUBSTG_RX}|#{PROPERTIES_RX}|#{NAMEID_RX}/

			attr_reader :nameid

			def initialize
				@nameid = nil
				# not exactly a cache currently
				@cache = {}
			end

			#--
			# The parsing methods
			#++

			def self.load obj
				prop = new
				prop.load obj
				prop
			end

			# Parse properties from the +Dirent+ obj
			def load obj
				# we need to do the nameid first, as it provides the map for later user defined properties
				if nameid_obj = obj.children.find { |child| child.name =~ NAMEID_RX }
					@nameid = PropertyStore.parse_nameid nameid_obj
					# hack to make it available to all msg files from the same ole storage object
					# FIXME - come up with a neater way
					class << obj.ole
						attr_accessor :msg_nameid
					end
					obj.ole.msg_nameid = @nameid
				elsif obj.ole
					@nameid = obj.ole.msg_nameid rescue nil
				end
				# now parse the actual properties. i think dirs that match the substg should be decoded
				# as properties to. 0x000d is just another encoding, the dir encoding. it should match
				# whether the object is file / dir. currently only example is embedded msgs anyway
				obj.children.each do |child|
					next unless child.file?
					case child.name
					when PROPERTIES_RX
						parse_properties child
					when SUBSTG_RX
						parse_substg(*($~[1..-1].map { |num| num.hex rescue nil } + [child]))
					end
				end
			end

			# Read nameid from the +Dirent+ obj, which is used for mapping of named properties keys to
			# proxy keys in the 0x8000 - 0xffff range.
			# Returns a hash of integer -> Key.
			def self.parse_nameid obj
				remaining = obj.children.dup
				guids_obj, props_obj, names_obj =
					%w[__substg1.0_00020102 __substg1.0_00030102 __substg1.0_00040102].map do |name|
						remaining.delete obj/name
					end

				# parse guids
				# this is the guids for named properities (other than builtin ones)
				# i think PS_PUBLIC_STRINGS, and PS_MAPI are builtin.
				guids = [PS_PUBLIC_STRINGS] + guids_obj.read.scan(/.{16}/m).map do |str|
					Ole::Types.load_guid str
				end

				# parse names.
				# the string ids for named properties
				# they are no longer parsed, as they're referred to by offset not
				# index. they are simply sequentially packed, as a long, giving
				# the string length, then padding to 4 byte multiple, and repeat.
				names_data = names_obj.read

				# parse actual props.
				# not sure about any of this stuff really.
				# should flip a few bits in the real msg, to get a better understanding of how this works.
				props = props_obj.read.scan(/.{8}/m).map do |str|
					flags, offset = str[4..-1].unpack 'v2'
					# the property will be serialised as this pseudo property, mapping it to this named property
					pseudo_prop = 0x8000 + offset
					named = flags & 1 == 1
					prop = if named
						str_off = *str.unpack('V')
						len = *names_data[str_off, 4].unpack('V')
						Ole::Types::FROM_UTF16.iconv names_data[str_off + 4, len]
					else
						a, b = str.unpack('v2')
						Log.debug "b not 0" if b != 0
						a
					end
					# a bit sus
					guid_off = flags >> 1
					# missing a few builtin PS_*
					Log.debug "guid off < 2 (#{guid_off})" if guid_off < 2
					guid = guids[guid_off - 2]
					[pseudo_prop, Key.new(prop, guid)]
				end

				#Log.warn "* ignoring #{remaining.length} objects in nameid" unless remaining.empty?
				# this leaves a bunch of other unknown chunks of data with completely unknown meaning.
				# pp [:unknown, child.name, child.data.unpack('H*')[0].scan(/.{16}/m)]
				Hash[*props.flatten]
			end

			# Parse an +Dirent+, as per <tt>msgconvert.pl</tt>. This is how larger properties, such
			# as strings, binary blobs, and other ole sub-directories (eg nested Msg) are stored.
			def parse_substg key, encoding, offset, obj
				if (encoding & 0x1000) != 0
					if !offset
						# there is typically one with no offset first, whose data is a series of numbers
						# equal to the lengths of all the sub parts. gives an implied array size i suppose.
						# maybe you can initialize the array at this time. the sizes are the same as all the
						# ole object sizes anyway, its to pre-allocate i suppose.
						#p obj.data.unpack('V*')
						# ignore this one
						return
					else
						# remove multivalue flag for individual pieces
						encoding &= ~0x1000
					end
				else
					Log.warn "offset specified for non-multivalue encoding #{obj.name}" if offset
					offset = nil
				end
				# offset is for multivalue encodings.
				unless encoder = ENCODINGS[encoding]
					Log.warn "unknown encoding #{encoding}"
					#encoder = proc { |obj| obj.io } #.read }. maybe not a good idea
					encoder = ENCODINGS[:default]
				end
				add_property key, encoder[obj], offset
			end

			# For parsing the +properties+ file. Smaller properties are serialized in one chunk,
			# such as longs, bools, times etc. The parsing has problems.
			def parse_properties obj
				data = obj.read
				# don't really understand this that well...
				pad = data.length % 16
				unless (pad == 0 || pad == 8) and data[0...pad] == "\000" * pad
					Log.warn "padding was not as expected #{pad} (#{data.length}) -> #{data[0...pad].inspect}"
				end
				data[pad..-1].scan(/.{16}/m).each do |data|
					property, encoding = ('%08x' % data.unpack('V')).scan /.{4}/
					key = property.hex
					# doesn't make any sense to me. probably because its a serialization of some internal
					# outlook structure...
					next if property == '0000'
					case encoding
					when '0102', '001e', '001f', '101e', '101f', '000d'
						# ignore on purpose. not sure what its for
						# multivalue versions ignored also
					when '0003' # long
						# don't know what all the other data is for
						add_property key, *data[8, 4].unpack('V')
					when '000b' # boolean
						# again, heaps more data than needed. and its not always 0 or 1.
						# they are in fact quite big numbers. this is wrong.
# 					p [property, data[4..-1].unpack('H*')[0]]
						add_property key, data[8, 4].unpack('V')[0] != 0
					when '0040' # systime
						# seems to work:
						add_property key, Ole::Types.load_time(data[8..-1])
					else
						#Log.warn "ignoring data in __properties section, encoding: #{encoding}"
						#Log << data.unpack('H*').inspect + "\n"
					end
				end
			end

			def add_property key, value, pos=nil
				# map keys in the named property range through nameid
				if Integer === key and key >= 0x8000
					if !@nameid
						Log.warn "no nameid section yet named properties used"
						key = Key.new key
					elsif real_key = @nameid[key]
						key = real_key
					else
						# i think i hit these when i have a named property, in the PS_MAPI
						# guid
						Log.warn "property in named range not in nameid #{key.inspect}"
						key = Key.new key
					end
				else
					key = Key.new key
				end
				if pos
					@cache[key] ||= []
					Log.warn "duplicate property" unless Array === @cache[key]
					# ^ this is actually a trickier problem. the issue is more that they must all be of
					# the same type.
					@cache[key][pos] = value
				else
					# take the last.
					Log.warn "duplicate property #{key.inspect}" if @cache[key]
					@cache[key] = value
				end
			end

			# delegate to cache
			def method_missing name, *args, &block
				@cache.send name, *args, &block
			end
		end

		# these 2 will actually be of the form
		# 1\.0_#([0-9A-Z]{8}), where $1 is the 0 based index number in hex
		# should i parse that and use it as an index, or just return in
		# file order? probably should use it later...
		ATTACH_RX = /^__attach_version1\.0_.*/
		RECIP_RX = /^__recip_version1\.0_.*/
		VALID_RX = /#{PropertyStore::VALID_RX}|#{ATTACH_RX}|#{RECIP_RX}/

		attr_reader :root
		attr_accessor :close_parent

		# Alternate constructor, to create an +Msg+ directly from +arg+ and +mode+, passed
		# directly to Ole::Storage (ie either filename or seekable IO object).
		def self.open arg, mode=nil
			msg = new Ole::Storage.open(arg, mode).root
			# we will close the ole when we are #closed
			msg.close_parent = true
			if block_given?
				begin   yield msg
				ensure; msg.close
				end
			else msg
			end
		end

		# Create an Msg from +root+, an <tt>Ole::Storage::Dirent</tt> object
		def initialize root
			@root = root
			@close_parent = false
			super PropertySet.new(PropertyStore.load(@root))
			Msg.warn_unknown @root
		end

		def self.warn_unknown obj
			# bit of validation. not important if there is extra stuff, though would be
			# interested to know what it is. doesn't check dir/file stuff.
			unknown = obj.children.reject { |child| child.name =~ VALID_RX }
			Log.warn "skipped #{unknown.length} unknown msg object(s)" unless unknown.empty?
		end

		def close
			@root.ole.close if @close_parent
		end

		def attachments
			@attachments ||= @root.children.
				select { |child| child.dir? and child.name =~ ATTACH_RX }.
				map { |child| Attachment.new child }.
				select { |attach| attach.valid? }
		end

		def recipients
			@recipients ||= @root.children.
				select { |child| child.dir? and child.name =~ RECIP_RX }.
				map { |child| Recipient.new child }
		end

		class Attachment < Mapi::Attachment
			attr_reader :obj, :properties
			alias props :properties

			def initialize obj
				@obj = obj
				@embedded_ole = nil
				@embedded_msg = nil

				super PropertySet.new(PropertyStore.load(@obj))
				Msg.warn_unknown @obj

				@obj.children.each do |child|
					# temp hack. PropertyStore doesn't do directory properties atm - FIXME
					if child.dir? and child.name =~ PropertyStore::SUBSTG_RX and
						 $1 == '3701' and $2.downcase == '000d'
						@embedded_ole = child
						class << @embedded_ole
							def compobj
								return nil unless compobj = self["\001CompObj"]
								compobj.read[/^.{32}([^\x00]+)/m, 1]
							end

							def embedded_type
								temp = compobj and return temp
								# try to guess more
								if children.select { |child| child.name =~ /__(substg|properties|recip|attach|nameid)/ }.length > 2
									return 'Microsoft Office Outlook Message'
								end
								nil
							end
						end
						if @embedded_ole.embedded_type == 'Microsoft Office Outlook Message'
							@embedded_msg = Msg.new @embedded_ole
						end
					end
				end
			end

			def valid?
				# something i started to notice when handling embedded ole object attachments is
				# the particularly strange case where there are empty attachments
				not props.raw.keys.empty?
			end
		end

		#
		# +Recipient+ serves as a container for the +recip+ directories in the .msg.
		# It has things like office_location, business_telephone_number, but I don't
		# think enough to make a vCard out of?
		#
		class Recipient < Mapi::Recipient
			attr_reader :obj, :properties
			alias props :properties

			def initialize obj
				@obj = obj
				super PropertySet.new(PropertyStore.load(@obj))
				Msg.warn_unknown @obj
			end
		end
	end
end

