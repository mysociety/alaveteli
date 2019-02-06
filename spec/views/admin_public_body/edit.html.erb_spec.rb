require 'spec_helper'

describe 'admin_public_body/edit.html.erb' do
  let(:public_body) { FactoryBot.create(:public_body) }

  before do
    assign :public_body, public_body
  end

  it 'shows and enables the button for destroying the body' do
    render template: 'admin_public_body/edit'
    expect(rendered).
      to have_button("Destroy #{public_body.name}", disabled: false)
  end

  context 'when the body has associated requests' do

    before do
      assign :hide_destroy_button, true
    end

    it 'disables the button for destroying the body' do
      render template: 'admin_public_body/edit'
      expect(rendered).
        to have_button("Destroy #{public_body.name}", disabled: true)
    end

  end

end
