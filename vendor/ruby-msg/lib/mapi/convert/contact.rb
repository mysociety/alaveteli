require 'rubygems'
require 'vpim/vcard'

# patch Vpim. TODO - fix upstream, or verify old behaviour was ok
def Vpim.encode_text v
	# think the regexp was wrong
	v.to_str.gsub(/(.)/m) do
		case $1
		when "\n"
			"\\n"
		when "\\", ",", ";"
			"\\#{$1}"
		else
			$1
		end
	end
end

module Mapi
	class Message
		class VcardConverter
			include Vpim

			# a very incomplete mapping, but its a start...
			# can't find where to set a lot of stuff, like zipcode, jobtitle etc
			VCARD_MAP = {
				# these are all standard mapi properties
				:name => [
					{
						:given		=> :given_name,
						:family		=> :surname,
						:fullname	=> :subject
					}
				],
				# outlook seems to eschew the mapi properties this time,
				# like postal_address, street_address, home_address_city
				# so we use the named properties
				:addr => [
					{
						:location	=> 'work',
						:street		=> :business_address_street,
						:locality	=> proc do |props|
							[props.business_address_city, props.business_address_state].compact * ', '
						end
					}
				],

				# right type? maybe date
				:birthday	=> :birthday,
				:nickname	=> :nickname

				# photo available?
				# FIXME finish, emails, telephones etc
			}

			attr_reader :msg
			def initialize msg
				@msg = msg
			end

			def field name, *args
				DirectoryInfo::Field.create name, Vpim.encode_text_list(args)
			end

			def get_property key
				if String === key
					return key
				elsif key.respond_to? :call
					value = key.call msg.props
				else
					value = msg.props[key]
				end
				if String === value and value.empty?
					nil
				else
					value
				end
			end

			def get_properties hash
				constants = {}
				others = {}
				hash.each do |to, from|
					if String === from
						constants[to] = from
					else
						value = get_property from
						others[to] = value if value
					end
				end
				return nil if others.empty?
				others.merge constants
			end

			def convert
				Vpim::Vcard::Maker.make2 do |m|
					# handle name
					[:name, :addr].each do |type|
						VCARD_MAP[type].each do |hash|
							next unless props = get_properties(hash)
							m.send "add_#{type}" do |n|
								props.each { |key, value| n.send "#{key}=", value }
							end
						end
					end

					(VCARD_MAP.keys - [:name, :addr]).each do |key|
						value = get_property VCARD_MAP[key]
						m.send "#{key}=", value if value
					end

					# the rest of the stuff is custom

					url = get_property(:webpage) || get_property(:business_home_page)
					m.add_field field('URL', url) if url
					m.add_field field('X-EVOLUTION-FILE-AS', get_property(:file_under)) if get_property(:file_under)

					addr = get_property(:email_email_address) || get_property(:email_original_display_name)
					if addr
						m.add_email addr do |e|
							e.format ='x400' unless msg.props.email_addr_type == 'SMTP'
						end
					end

					if org = get_property(:company_name)
						m.add_field field('ORG', get_property(:company_name))
					end

					# TODO: imaddress
				end
			end
		end

		def to_vcard
			#p props.raw.reject { |key, value| key.guid.inspect !~ /00062004-0000-0000-c000-000000000046/ }.
			#	map { |key, value| [key.to_sym, value] }.reject { |a, b| b.respond_to? :read }
			#y props.to_h.reject { |a, b| b.respond_to? :read }
			VcardConverter.new(self).convert
		end
	end
end

