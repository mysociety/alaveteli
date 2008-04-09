atom_feed do |feed|
    feed.title(@track_thing.params[:title_in_rss])

    for search_result in @search_results
        feed.entry(search_result) do |entry|
            # Get the HTML content from the same partial template as website search does
            content = ''
            if search_result.class.to_s == 'InfoRequestEvent'
                content += render :partial => 'request/request_listing_via_event', :locals => { :event => search_result, :info_request => search_result.info_request }
            else
                content = "<p><strong>Unknown search result type " + search_result.class.to_s + "</strong></p>"
            end
            # Pull out the heading as separate item, from the partial template
            content.match(/(<a href="[^>]*">(.*)<\/a>\s+<br>)/)
            heading = $1
            heading_text = $2
            content.sub!(heading, "")
            # Render the atom
            entry.title(heading_text, :type => 'html')
            entry.content(content, :type => 'html')
        end
    end
end

