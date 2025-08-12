require 'spec_helper'

RSpec.describe "admin_user/_user_table.html.erb" do
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:users) do
    user_array = [
      FactoryBot.create(:user, name: "Samuel Beckett"),
      FactoryBot.create(:user, name: "Fintan O'Toole")
    ]
    allow(user_array).to receive(:total_pages).and_return(1)
    user_array
  end

  it 'does not double escape apostrophes' do
    allow(controller).to receive(:current_user).and_return(admin_user)
    render partial: 'admin_user/user_table.html.erb',
           locals: { users: users,
                     banned_column: false }
    expect(rendered).to match("O&#39;Toole")
  end
end
