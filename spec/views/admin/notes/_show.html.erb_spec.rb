require 'spec_helper'

RSpec.describe 'admin/notes/show' do
  subject { rendered }

  def render_view
    render partial: self.class.top_level_description,
           locals: { notes: notes, notable: notable }
  end

  before { render_view }

  context 'with notes' do
    let(:notes) { FactoryBot.create_list(:note, 2) }
    let(:notable) { double }
    # TODO: Improve CSS class name
    it { is_expected.to match(/censor-rule-list/) }
  end

  context 'with no notes' do
    let(:notes) { [] }
    let(:notable) { double }
    it { is_expected.to match(/None yet/) }
  end

  context 'with a notable' do
    let(:notes) { [] }
    let(:notable) { double }
    it { is_expected.to match(/New note/) }
  end

  context 'with no notable' do
    let(:notes) { [] }
    let(:notable) { nil }
    it { is_expected.not_to match(/New note/) }
  end
end
