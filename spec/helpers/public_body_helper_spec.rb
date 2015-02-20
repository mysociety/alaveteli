require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PublicBodyHelper do
  include PublicBodyHelper

  describe :public_body_not_requestable_reasons do

    before do
      @body = FactoryGirl.build(:public_body)
    end

    it 'returns an empty array if there are no reasons' do
      expect(public_body_not_requestable_reasons(@body)).to eq([])
    end

    it 'includes a reason if the law does not apply to the authority' do
      @body.tag_string = 'not_apply'
      msg = 'Freedom of Information law does not apply to this authority, so you cannot make a request to it.'
      expect(public_body_not_requestable_reasons(@body)).to include(msg)
    end

    it 'includes a reason if the body no longer exists' do
      @body.tag_string = 'defunct'
      msg = 'This authority no longer exists, so you cannot make a request to it.'
      expect(public_body_not_requestable_reasons(@body)).to include(msg)
    end 

    it 'links to the request page if the body has no contact email' do
      @body.request_email = ''
      msg = %Q(<a href="/new/#{ @body.url_name }"
               class="link_button_green">Make
               a request to this authority</a>).squish

      expect(public_body_not_requestable_reasons(@body)).to include(msg)
    end

    it 'returns the reasons in order of importance' do
      @body.tag_string = 'defunct not_apply'
      @body.request_email = ''

      reasons = public_body_not_requestable_reasons(@body)

      expect(reasons[0]).to match(/no longer exists/)
      expect(reasons[1]).to match(/does not apply/)
      expect(reasons[2]).to match(/Make a request/)
    end

  end

end
