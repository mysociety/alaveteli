require 'spec_helper'

RSpec.describe 'general/_site_wide_announcement.html.erb' do

  let(:announcement) do
    FactoryBot.
      create(:announcement,
             content: '<b>Exciting news!</b> <script>alert("!")</script>')
  end

  before do
    allow(view).to receive(:current_user).and_return(FactoryBot.build(:user))
  end

  describe 'displaying an announcement' do

    it 'shows the announcement' do
      render template: 'general/_site_wide_announcement',
             locals: { announcement: announcement }
      expect(rendered).to include('Introducing projects')
      expect(rendered).to include('<b>Exciting news!</b>')
    end

    it 'strips out dangerous tags' do
      render template: 'general/_site_wide_announcement',
             locals: { announcement: announcement }
      expect(rendered).not_to include('<script>')
    end

  end

end
