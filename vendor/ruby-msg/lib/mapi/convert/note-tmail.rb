require 'rubygems'
require 'tmail'

# these will be removed later
require 'time'
require 'mime'

# there is some Msg specific stuff in here.

class TMail::Mail
	def quoted_body= str
		body_port.wopen { |f| f.write str }
		str
	end
end

module Mapi
	class Message
		def mime
			return @mime if @mime
			# if these headers exist at all, they can be helpful. we may however get a
			# application/ms-tnef mime root, which means there will be little other than
			# headers. we may get nothing.
			# and other times, when received from external, we get the full cigar, boundaries
			# etc and all.
			# sometimes its multipart, with no boundaries. that throws an error. so we'll be more
			# forgiving here
			@mime = Mime.new props.transport_message_headers.to_s, true
			populate_headers
			@mime
		end

		def headers
			mime.headers
		end

		# copy data from msg properties storage to standard mime. headers
		# i've now seen it where the existing headers had heaps on stuff, and the msg#props had
		# practically nothing. think it was because it was a tnef - msg conversion done by exchange.
		def populate_headers
			# construct a From value
			# should this kind of thing only be done when headers don't exist already? maybe not. if its
			# sent, then modified and saved, the headers could be wrong?
			# hmmm. i just had an example where a mail is sent, from an internal user, but it has transport
			# headers, i think because one recipient was external. the only place the senders email address
			# exists is in the transport headers. so its maybe not good to overwrite from.
			# recipients however usually have smtp address available.
			# maybe we'll do it for all addresses that are smtp? (is that equivalent to 
			# sender_email_address !~ /^\//
			name, email = props.sender_name, props.sender_email_address
			if props.sender_addrtype == 'SMTP'
				headers['From'] = if name and email and name != email
					[%{"#{name}" <#{email}>}]
				else
					[email || name]
				end
			elsif !headers.has_key?('From')
				# some messages were never sent, so that sender stuff isn't filled out. need to find another
				# way to get something
				# what about marking whether we thing the email was sent or not? or draft?
				# for partition into an eventual Inbox, Sent, Draft mbox set?
				# i've now seen cases where this stuff is missing, but exists in transport message headers,
				# so maybe i should inhibit this in that case.
				if email
					# disabling this warning for now
					#Log.warn "* no smtp sender email address available (only X.400). creating fake one"
					# this is crap. though i've specially picked the logic so that it generates the correct
					# email addresses in my case (for my organisation).
					# this user stuff will give valid email i think, based on alias.
					user = name ? name.sub(/(.*), (.*)/, "\\2.\\1") : email[/\w+$/].downcase
					domain = (email[%r{^/O=([^/]+)}i, 1].downcase + '.com' rescue email)
					headers['From'] = [name ? %{"#{name}" <#{user}@#{domain}>} : "<#{user}@#{domain}>" ]
				elsif name
					# we only have a name? thats screwed up.
					# disabling this warning for now
					#Log.warn "* no smtp sender email address available (only name). creating fake one"
					headers['From'] = [%{"#{name}"}]
				else
					# disabling this warning for now
					#Log.warn "* no sender email address available at all. FIXME"
				end
			# else we leave the transport message header version
			end

			# for all of this stuff, i'm assigning in utf8 strings.
			# thats ok i suppose, maybe i can say its the job of the mime class to handle that.
			# but a lot of the headers are overloaded in different ways. plain string, many strings
			# other stuff. what happens to a person who has a " in their name etc etc. encoded words
			# i suppose. but that then happens before assignment. and can't be automatically undone
			# until the header is decomposed into recipients.
			recips_by_type = recipients.group_by { |r| r.type }
			# i want to the the types in a specific order.
			[:to, :cc, :bcc].each do |type|
				# don't know why i bother, but if we can, we try to sort recipients by the numerical part
				# of the ole name, or just leave it if we can't
				recips = recips_by_type[type]
				recips = (recips.sort_by { |r| r.obj.name[/\d{8}$/].hex } rescue recips)
				# switched to using , for separation, not ;. see issue #4
				# recips.empty? is strange. i wouldn't have thought it possible, but it was right?
				headers[type.to_s.sub(/^(.)/) { $1.upcase }] = [recips.join(', ')] unless recips.empty?
			end
			headers['Subject'] = [props.subject] if props.subject

			# fill in a date value. by default, we won't mess with existing value hear
			if !headers.has_key?('Date')
				# we want to get a received date, as i understand it.
				# use this preference order, or pull the most recent?
				keys = %w[message_delivery_time client_submit_time last_modification_time creation_time]
				time = keys.each { |key| break time if time = props.send(key) }
				time = nil unless Date === time

				# now convert and store
				# this is a little funky. not sure about time zone stuff either?
				# actually seems ok. maybe its always UTC and interpreted anyway. or can be timezoneless.
				# i have no timezone info anyway.
				# in gmail, i see stuff like 15 Jan 2007 00:48:19 -0000, and it displays as 11:48.
				# can also add .localtime here if desired. but that feels wrong.
				headers['Date'] = [Time.iso8601(time.to_s).rfc2822] if time
			end

			# some very simplistic mapping between internet message headers and the
			# mapi properties
			# any of these could be causing duplicates due to case issues. the hack in #to_mime
			# just stops re-duplication at that point. need to move some smarts into the mime
			# code to handle it.
			mapi_header_map = [
				[:internet_message_id, 'Message-ID'],
				[:in_reply_to_id, 'In-Reply-To'],
				# don't set these values if they're equal to the defaults anyway
				[:importance, 'Importance', proc { |val| val.to_s == '1' ? nil : val }],
				[:priority, 'Priority', proc { |val| val.to_s == '1' ? nil : val }],
				[:sensitivity, 'Sensitivity', proc { |val| val.to_s == '0' ? nil : val }],
				# yeah?
				[:conversation_topic, 'Thread-Topic'],
				# not sure of the distinction here
				# :originator_delivery_report_requested ??
				[:read_receipt_requested, 'Disposition-Notification-To', proc { |val| from }]
			]
			mapi_header_map.each do |mapi, mime, *f|
				next unless q = val = props.send(mapi) or headers.has_key?(mime)
				next if f[0] and !(val = f[0].call(val))
				headers[mime] = [val.to_s]
			end
		end

		# redundant?
		def type
			props.message_class[/IPM\.(.*)/, 1].downcase rescue nil
		end

		# shortcuts to some things from the headers
		%w[From To Cc Bcc Subject].each do |key|
			define_method(key.downcase) { headers[key].join(' ') if headers.has_key?(key) }
		end

		def body_to_tmail
			# to create the body
			# should have some options about serializing rtf. and possibly options to check the rtf
			# for rtf2html conversion, stripping those html tags or other similar stuff. maybe want to
			# ignore it in the cases where it is generated from incoming html. but keep it if it was the
			# source for html and plaintext.
			if props.body_rtf or props.body_html
				# should plain come first?
				part = TMail::Mail.new
				# its actually possible for plain body to be empty, but the others not.
				# if i can get an html version, then maybe a callout to lynx can be made...
				part.parts << TMail::Mail.parse("Content-Type: text/plain\r\n\r\n" + props.body) if props.body
				# this may be automatically unwrapped from the rtf if the rtf includes the html
				part.parts << TMail::Mail.parse("Content-Type: text/html\r\n\r\n"  + props.body_html) if props.body_html
				# temporarily disabled the rtf. its just showing up as an attachment anyway.
				#mime.parts << Mime.new("Content-Type: text/rtf\r\n\r\n"   + props.body_rtf)  if props.body_rtf
				# its thus currently possible to get no body at all if the only body is rtf. that is not
				# really acceptable FIXME
				part['Content-Type'] = 'multipart/alternative'
				part
			else
				# check no header case. content type? etc?. not sure if my Mime class will accept
				Log.debug "taking that other path"
				# body can be nil, hence the to_s
				TMail::Mail.parse "Content-Type: text/plain\r\n\r\n" + props.body.to_s
			end
		end

		def to_tmail
			# intended to be used for IPM.note, which is the email type. can use it for others if desired,
			# YMMV
			Log.warn "to_mime used on a #{props.message_class}" unless props.message_class == 'IPM.Note'
			# we always have a body
			mail = body = body_to_tmail

			# If we have attachments, we take the current mime root (body), and make it the first child
			# of a new tree that will contain body and attachments.
			unless attachments.empty?
				raise NotImplementedError
				mime = Mime.new "Content-Type: multipart/mixed\r\n\r\n"
				mime.parts << body
				# i don't know any better way to do this. need multipart/related for inline images
				# referenced by cid: urls to work, but don't want to use it otherwise...
				related = false
				attachments.each do |attach|
					part = attach.to_mime
					related = true if part.headers.has_key?('Content-ID') or part.headers.has_key?('Content-Location')
					mime.parts << part
				end
				mime.headers['Content-Type'] = ['multipart/related'] if related
			end

			# at this point, mime is either
			# - a single text/plain, consisting of the body ('taking that other path' above. rare)
			# - a multipart/alternative, consiting of a few bodies (plain and html body. common)
			# - a multipart/mixed, consisting of 1 of the above 2 types of bodies, and attachments.
			# we add this standard preamble if its multipart
			# FIXME preamble.replace, and body.replace both suck.
			# preamble= is doable. body= wasn't being done because body will get rewritten from parts
			# if multipart, and is only there readonly. can do that, or do a reparse...
			# The way i do this means that only the first preamble will say it, not preambles of nested
			# multipart chunks.
			mail.quoted_body = "This is a multi-part message in MIME format.\r\n" if mail.multipart?

			# now that we have a root, we can mix in all our headers
			headers.each do |key, vals|
				# don't overwrite the content-type, encoding style stuff
				next if mail[key]
				# some new temporary hacks
				next if key =~ /content-type/i and vals[0] =~ /base64/
				#next if mime.headers.keys.map(&:downcase).include? key.downcase
				mail[key] = vals.first
			end
			# just a stupid hack to make the content-type header last, when using OrderedHash
			#mime.headers['Content-Type'] = mime.headers.delete 'Content-Type'

			mail
		end
	end

	class Attachment
		def to_tmail
			# TODO: smarter mime typing.
			mimetype = props.attach_mime_tag || 'application/octet-stream'
			part = TMail::Mail.parse "Content-Type: #{mimetype}\r\n\r\n"
			part['Content-Disposition'] = %{attachment; filename="#{filename}"}
			part['Content-Transfer-Encoding'] = 'base64'
			part['Content-Location'] = props.attach_content_location if props.attach_content_location
			part['Content-ID'] = props.attach_content_id if props.attach_content_id
			# data.to_s for now. data was nil for some reason.
			# perhaps it was a data object not correctly handled?
			# hmmm, have to use read here. that assumes that the data isa stream.
			# but if the attachment data is a string, then it won't work. possible?
			data_str = if @embedded_msg
				raise NotImplementedError
				mime.headers['Content-Type'] = 'message/rfc822'
				# lets try making it not base64 for now
				mime.headers.delete 'Content-Transfer-Encoding'
				# not filename. rather name, or something else right?
				# maybe it should be inline?? i forget attach_method / access meaning
				mime.headers['Content-Disposition'] = [%{attachment; filename="#{@embedded_msg.subject}"}]
				@embedded_msg.to_mime.to_s
			elsif @embedded_ole
				raise NotImplementedError
				# kind of hacky
				io = StringIO.new
				Ole::Storage.new io do |ole|
					ole.root.type = :dir
					Ole::Storage::Dirent.copy @embedded_ole, ole.root
				end
				io.string
			else
				data.read.to_s
			end
			part.body = @embedded_msg ? data_str : Base64.encode64(data_str).gsub(/\n/, "\r\n")
			part
		end
	end

	class Msg < Message
		def populate_headers
			super
			if !headers.has_key?('Date')
				# can employ other methods for getting a time. heres one in a similar vein to msgconvert.pl,
				# ie taking the time from an ole object
				time = @root.ole.dirents.map { |dirent| dirent.modify_time || dirent.create_time }.compact.sort.last
				headers['Date'] = [Time.iso8601(time.to_s).rfc2822] if time
			end
		end
	end
end

