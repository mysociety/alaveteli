module AlaveteliTextFormat

    # Returns text with obvious links made into HTML hrefs.
    # Taken originally from phplib/utility.php and from WordPress, tweaked somewhat.
    # Text passed into here should already have been passed through e.g. CGI.escapeHTML
    def self.make_clickable(text, params = {})
        nofollow = params[:nofollow]
        contract = params[:contract]
        ret = ' ' + text + ' '

        # Special case as we get already HTML encoded < and > at end and start
        # of URLs often, when used to bracket them
        # e.g. http://www.whatdotheyknow.com/request/records_of_tenancy_property#incoming-212
        ret = ret.gsub(/&lt;/, " LTCODE ")
        ret = ret.gsub(/&gt;/, " GTCODE ")

        # Sometimes get angle bracketed URLs with newlines in the middle of them.
        # http://www.whatdotheyknow.com/request/advice_sought_from_information_c#incoming-24711
        ret = ret.gsub(/( LTCODE http[\S\r\n]*? GTCODE )/) { |m| m.gsub(/[\n\r]/, "") }

        ret = ret.gsub(/(https?):\/\/([^\s<>]+[^\s.,<>])/i, '<a href="\\1://\\2"' + (nofollow ? ' rel="nofollow"' : "") + ">\\1://\\2</a>")
        ret = ret.gsub(/(\s)www\.([a-z0-9\-]+)((?:\.[a-z0-9\-\~]+)+)((?:\/[^ <>\n\r]*[^., <>\n\r])?)/i,
                    '\\1<a href="http://www.\\2\\3\\4"' + (nofollow ? ' rel="nofollow"' : "") + ">www.\\2\\3\\4</a>")
        if contract
            ret = ret.gsub(/(<a href="[^"]*"(?: rel="nofollow")?>)([^<]{40})[^<]{3,}<\/a>/, "\\1\\2...</a>")
        end
        ret = ret.gsub(/(\s)([a-z0-9\-_.]+)@([^,< \n\r]*[^.,< \n\r])/i, "\\1<a href=\"mailto:\\2@\\3\">\\2@\\3</a>")

        # Put back the codes for < and >
        ret = ret.gsub(" LTCODE ", "&lt;")
        ret = ret.gsub(" GTCODE ", "&gt;")

        ret = ret.strip
        return ret
    end

end