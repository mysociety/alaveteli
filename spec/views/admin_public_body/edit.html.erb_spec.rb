require 'spec_helper'

describe 'admin_public_body/edit.html.erb' do
  let(:public_body) { FactoryBot.create(:public_body) }

  before do
    assign :public_body, public_body
  end

  it 'shows the button for destroying the body' do
    render template: 'admin_public_body/edit'
    expect(rendered).to have_button("Destroy #{public_body.name}")
  end

  context 'when the body has associated requests' do

    before do
      assign :hide_destroy_button, true
    end

    it 'does not show the button for destroying the body' do
      render template: 'admin_public_body/edit'
      expect(rendered).not_to have_button("Destroy #{public_body.name}")
    end

  end

end
