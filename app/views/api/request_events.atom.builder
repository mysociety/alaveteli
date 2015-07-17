atom_feed("xmlns:alaveteli" => "http://www.alaveteli.org/API/v2/RequestEvents/Atom") do |feed|
  feed.title("Events relating to #{@public_body.name}")
  feed.updated(@events.first.created_at)

  for event in @events
    feed.entry(event) do |entry|
      request = event.info_request

      entry.updated(event.created_at.utc.iso8601)
      entry.tag!("alaveteli:event_type", event.event_type)
      entry.tag!("alaveteli:request_url", request_url(request))
      entry.title(request.title)

      entry.content(event.outgoing_message.body, :type => 'text')

      entry.author do |author|
        author.name(request.user_name)
        if !request.user.nil?
          author.uri(user_url(request.user))
        end
        author.email(request.incoming_email)
      end
    end
  end
end
