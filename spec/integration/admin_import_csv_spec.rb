require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

RSpec.describe 'Importing a CSV' do

  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)

    confirm(:admin_user)
    @admin = login(:admin_user)
  end

  it 'uploads the file and attempts to read the contents' do
    using_session(@admin) do
      visit admin_bodies_path
      click_link 'Import from CSV file'
      attach_file('csv_file',
                  Rails.root + 'spec/fixtures/files/fake-authority-type.csv')
      click_button 'Dry run'

      expected = <<-EOF.strip_heredoc.gsub("\n", '')
'North West Fake Authority' (locale: en): {
"name":"North West Fake Authority","request_email":"north_west_foi@localhost"}
      EOF

      expect(page).to have_content(expected)
    end
  end

end
