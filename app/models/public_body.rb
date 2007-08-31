# XXX move this to somewhere shared
def is_valid_email(addr)
    # This is derived from the grammar in RFC2822.
    # mailbox = local-part "@" domain
    # local-part = dot-string | quoted-string
    # dot-string = atom ("." atom)*
    # atom = atext+
    # atext = any character other than space, specials or controls
    # quoted-string = '"' (qtext|quoted-pair)* '"'
    # qtext = any character other than '"', '\', or CR
    # quoted-pair = "\" any character
    # domain = sub-domain ("." sub-domain)* | address-literal
    # sub-domain = [A-Za-z0-9][A-Za-z0-9-]*
    # XXX ignore address-literal because nobody uses those...

    specials = '()<>@,;:\\\\".\\[\\]'
    controls = '\\000-\\037\\177'
    highbit = '\\200-\\377'
    atext = "[^#{specials} #{controls}#{highbit}]"
    atom = "#{atext}+"
    dot_string = "#{atom}(\\s*\\.\\s*#{atom})*"
    qtext = "[^\"\\\\\\r\\n#{highbit}]"
    quoted_pair = '\\.'
    quoted_string = "\"(#{qtext}|#{quoted_pair})*\""
    local_part = "(#{dot_string}|#{quoted_string})"
    sub_domain = '[A-Za-z0-9][A-Za-z0-9-]*'
    domain = "#{sub_domain}(\\s*\\.\\s*#{sub_domain})*"

    is_valid_address_re = Regexp.new("^#{local_part}\\s*@\\s*#{domain}\$")

    return addr =~ is_valid_address_re
end

class PublicBody < ActiveRecord::Base
    validates_presence_of :request_email

    def validate
        unless is_valid_email(request_email)
            errors.add(:request_email, "doesn't look like a valid email address")
        end
        if complaint_email != ""
            unless is_valid_email(complaint_email)
                errors.add(:complaint_email, "doesn't look like a valid email address")
            end
        end
    end

    acts_as_versioned
end
