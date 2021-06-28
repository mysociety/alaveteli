require 'spec_helper'

describe 'request/incoming_correspondence' do
  let(:info_request) { FactoryBot.create(:info_request_with_incoming) }
  let(:incoming_message) { info_request.incoming_messages.first }

  let(:stub_locals) do
    { incoming_message: incoming_message }
  end

  let(:ability) { Object.new.extend(CanCan::Ability) }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(view).to receive(:current_user).and_return(info_request.user)
    assign(:info_request, info_request)
  end

  context 'the current_user cannot read the request' do
    before { ability.cannot :read, incoming_message }

    it 'renders _hidden_correspondence if the current user cannot read the request' do
      render partial: self.class.top_level_description,
             locals: stub_locals

      expected = 'request/_hidden_correspondence'
      expect(rendered).to render_template(partial: expected)
    end
  end

  context 'the current_user can read the request' do
    before { ability.can :read, incoming_message }

    # TODO: Add better generic success case

    it 'does not include HTML time tags' do
      render partial: self.class.top_level_description,
             locals: stub_locals,
             formats: [:text]

      expect(rendered).not_to match(/<time.*>/)
    end
  end
end
