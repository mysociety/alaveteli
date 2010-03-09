require 'mapi/types'
require 'mapi/property_set'

module Mapi
	VERSION = '1.4.0'

	#
	# Mapi::Item is the base class used for all mapi objects, and is purely a
	# property set container
	#
	class Item
		attr_reader :properties
		alias props properties

		# +properties+ should be a PropertySet instance.
		def initialize properties
			@properties = properties
		end
	end

	# a general attachment class. is subclassed by Msg and Pst attachment classes
	class Attachment < Item
		def filename
			props.attach_long_filename || props.attach_filename
		end

		def data
			@embedded_msg || @embedded_ole || props.attach_data
		end

		# with new stream work, its possible to not have the whole thing in memory at one time,
		# just to save an attachment
		#
		# a = msg.attachments.first
		# a.save open(File.basename(a.filename || 'attachment'), 'wb') 
		def save io
			raise "can only save binary data blobs, not ole dirs" if @embedded_ole
			data.each_read { |chunk| io << chunk }
		end

		def inspect
			"#<#{self.class.to_s[/\w+$/]}" +
				(filename ? " filename=#{filename.inspect}" : '') +
				(@embedded_ole ? " embedded_type=#{@embedded_ole.embedded_type.inspect}" : '') + ">"
		end
	end
	
	class Recipient < Item
		# some kind of best effort guess for converting to standard mime style format.
		# there are some rules for encoding non 7bit stuff in mail headers. should obey
		# that here, as these strings could be unicode
		# email_address will be an EX:/ address (X.400?), unless external recipient. the
		# other two we try first.
		# consider using entry id for this too.
		def name
			name = props.transmittable_display_name || props.display_name
			# dequote
			name[/^'(.*)'/, 1] or name rescue nil
		end

		def email
			props.smtp_address || props.org_email_addr || props.email_address
		end

		RECIPIENT_TYPES = { 0 => :orig, 1 => :to, 2 => :cc, 3 => :bcc }
		def type
			RECIPIENT_TYPES[props.recipient_type]
		end

		def to_s
			if name = self.name and !name.empty? and email && name != email
				%{"#{name}" <#{email}>}
			else
				email || name
			end
		end

		def inspect
			"#<#{self.class.to_s[/\w+$/]}:#{self.to_s.inspect}>"
		end
	end

	# i refer to it as a message (as does mapi), although perhaps Item is better, as its a more general
	# concept than a message, as used in Pst files. though maybe i'll switch to using
	# Mapi::Object as the base class there.
	#
	# IMessage essentially, but there's also stuff like IMAPIFolder etc. so, for this to form
	# basis for PST Item, it'd need to be more general.
	class Message < Item
		# these 2 collections should be provided by our subclasses
		def attachments
			raise NotImplementedError
		end

		def recipients
			raise NotImplementedError
		end
		
		def inspect
			str = %w[message_class from to subject].map do |key|
				" #{key}=#{props.send(key).inspect}"
			end.compact.join
			str << " recipients=#{recipients.inspect}"
			str << " attachments=#{attachments.inspect}"
			"#<#{self.class.to_s[/\w+$/]}#{str}>"
		end
	end
end

