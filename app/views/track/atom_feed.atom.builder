atom_feed do |feed|
    feed.title(@track_thing.params[:title_in_rss])
    @highlight_words = @xapian_object.words_to_highlight

    for result in @xapian_object.results
        feed.entry(result[:model]) do |entry|
            # Get the HTML content from the same partial template as website search does
            content = ''
            if result[:model].class.to_s == 'InfoRequestEvent'
                content += render :partial => 'request/request_listing_via_event', :locals => { :event => result[:model], :info_request => result[:model].info_request }
            else
                content = "<p><strong>Unknown search result type " + result[:model].class.to_s + "</strong></p>"
            end
            # Pull out the heading as separate item, from the partial template
            content.match(/(<span class="head">\s+<a href="[^>]*">(.*)<\/a>\s+<\/span>)/)
            heading = $1
            heading_text = $2
            content.sub!(heading, "")
            # Render the atom
            entry.title(heading_text, :type => 'html')
            entry.content(content, :type => 'html')
        end
    end
end

