require 'spec_helper'

RSpec.describe 'comment/rate_limited.html.erb' do
  context 'with a comment' do
    let(:comment) { FactoryBot.build(:comment, body: 'The comment body') }

    before do
      assign :comment, comment
      render
    end

    it "renders the comment body for the user to save" do
      expect(rendered).to have_content('The comment body')
    end
  end
end
