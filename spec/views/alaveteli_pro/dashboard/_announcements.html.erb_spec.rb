require 'spec_helper'

RSpec.describe 'alaveteli_pro/dashboard/_announcements.html.erb' do

  let(:announcement) do
    FactoryBot.
      create(:announcement,
             content: '<b>Exciting news!</b> <script>alert("!")</script>')
  end

  before do
    assign :user, FactoryBot.create(:pro_user)
    assign :announcements, [announcement]
  end

  describe 'displaying an announcement' do

    it 'shows the announcement' do
      render template: 'alaveteli_pro/dashboard/_announcements'
      expect(rendered).to include('Introducing projects')
      expect(rendered).to include('<b>Exciting news!</b>')
    end

    it 'strips out dangerous tags' do
      render template: 'alaveteli_pro/dashboard/_announcements'
      expect(rendered).not_to include('<script>')
    end

  end

end
