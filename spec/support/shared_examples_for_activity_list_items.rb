shared_examples_for "an ActivityList::Item with standard #call_to_action" do

  describe '#call_to_action' do

    it 'returns the text "View"' do
      expect(activity.call_to_action).to eq('View')
    end

  end

end

shared_examples_for "an ActivityList::Item with standard #description_urls" do

  describe '#description_urls' do

    it 'returns a hash of :public_body_name and :info_request_title' do
      expected_urls = { :public_body_name =>
                        { :text => event.info_request.public_body.name,
                          :url => public_body_path(event.info_request.public_body) },
                        :info_request_title =>
                        { :text => event.info_request.title,
                          :url => request_path(event.info_request) } }
      expect(activity.description_urls).
        to eq expected_urls
    end
  end
end
