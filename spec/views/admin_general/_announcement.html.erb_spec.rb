require 'spec_helper'

describe 'admin_general/_announcement.html.erb' do

  let(:announcement) do
    FactoryBot.
      create(:announcement,
             visibility: 'admin',
             content: '<b>Exciting news!</b> <script>alert("!")</script>')
  end

  describe 'displaying an announcement' do

    it 'shows the announcement' do
      render template: 'admin_general/_announcement',
             locals: { announcement: announcement }
      expect(rendered).to include('Introducing projects')
      expect(rendered).to include('<b>Exciting news!</b>')
    end

    it 'strips out dangerous tags' do
      render template: 'admin_general/_announcement',
             locals: { announcement: announcement }
      expect(rendered).not_to include('<script>')
    end

  end

end
