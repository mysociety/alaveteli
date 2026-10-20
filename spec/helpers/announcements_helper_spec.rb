require 'spec_helper'

RSpec.describe AnnouncementsHelper do
  include AnnouncementsHelper

  describe '#announcement_as_html' do
    let(:announcement) do
      FactoryBot.build(:announcement, rich_body: '<b>Exciting news!</b>')
    end

    it { expect(announcement_as_html(announcement)).to eq('<b>Exciting news!</b>') }

    it 'strips out dangerous tags' do
      announcement.rich_body = '<b>Hi</b><script>alert("!")</script>'
      expect(announcement_as_html(announcement)).not_to include('<script>')
    end
  end

  describe '#announcement_style_class' do
    it 'returns a class for the style' do
      announcement = FactoryBot.build(:announcement, style: 'red')
      expect(announcement_style_class(announcement)).
        to eq('announcement--style-red')
    end
  end

  describe '#announcement_admin_alert_class' do
    {
      'red' => 'alert-error',
      'yellow' => 'alert-warning',
      'green' => 'alert-success',
      'blue' => 'alert-info',
      'default' => 'alert-info'
    }.each do |style, alert_class|
      it "maps #{style} to #{alert_class}" do
        announcement = FactoryBot.build(:announcement, style: style)
        expect(announcement_admin_alert_class(announcement)).to eq(alert_class)
      end
    end
  end
end
