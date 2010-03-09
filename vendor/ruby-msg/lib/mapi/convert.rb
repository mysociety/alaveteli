# we have two different "backends" for note conversion. we're sticking with
# the current (home grown) mime one until the tmail version is suitably
# polished.
require 'mapi/convert/note-mime'
require 'mapi/convert/contact'

module Mapi
	class Message
		CONVERSION_MAP = {
			'text/x-vcard'   => [:to_vcard, 'vcf'],
			'message/rfc822' => [:to_mime, 'eml'],
			'text/plain'     => [:to_post, 'txt']
			# ...
		}

		# get the mime type of the message. 
		def mime_type
			case props.message_class #.downcase <- have a feeling i saw other cased versions
			when 'IPM.Contact'
				# apparently "text/directory; profile=vcard" is what you're supposed to use
				'text/x-vcard'
			when 'IPM.Note'
				'message/rfc822'
			when 'IPM.Post'
				'text/plain'
			when 'IPM.StickyNote'
				'text/plain' # hmmm....
			else
				Mapi::Log.warn 'unknown message_class - %p' % props.message_class
				nil
			end
		end	

		def convert
			type = mime_type
			unless pair = CONVERSION_MAP[type]
				raise 'unable to convert message with mime type - %p' % type
			end
			send pair.first
		end

		# should probably be moved to mapi/convert/post
		class Post
			# not really sure what the pertinent properties are. we just do nothing for now...
			def initialize message
				@message = message
			end

			def to_s
				# should maybe handle other types, like html body. need a better format for post
				# probably anyway, cause a lot of meta data is getting chucked.
				@message.props.body
			end
		end

		def to_post
			Post.new self
		end
	end
end

