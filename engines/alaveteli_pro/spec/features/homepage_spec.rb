require 'spec_helper'

describe "Alaveteli Pro Homepage" do
  it "exists" do
    visit "/pro"
    expect(page).to have_text "Alaveteli Professional"
  end
end