require 'spec_helper'

RSpec.describe 'when displaying user info' do
  let(:user) { FactoryBot.build(:user, about_me: 'Foo bar') }

  before do
    assign :display_user, user
  end

  def render_view
    render partial: 'user/show_user_info'
  end

  context 'when instructed to render the about_me text' do
    before { assign :show_about_me, true }

    it 'shows the about_me text' do
      render_view
      expect(rendered).to have_text('Foo bar')
    end
  end

  context 'when instructed not to render the about_me text' do
    before { assign :show_about_me, false }

    it 'does not show the about_me text' do
      render_view
      expect(rendered).not_to have_text('Foo bar')
    end
  end
end
