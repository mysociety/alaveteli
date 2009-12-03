# Monkeypatch! Hack for admin pages, when proxied via https on mySociety servers, they
# need a relative URL.
module WillPaginate
    class LinkRenderer
        def page_link(page, text, attributes = {})
            url = url_for(page)
            if url.match(/^\/admin.*(\?.*)/)
                url = $1
            end
            @template.link_to text, url, attributes
        end
    end
end

