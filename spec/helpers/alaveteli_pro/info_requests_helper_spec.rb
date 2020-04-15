require 'spec_helper'

RSpec.describe AlaveteliPro::InfoRequestsHelper, type: :helper do
  describe '#embargo_extension_options' do
    context 'with an embargo' do
      subject { embargo_extension_options(embargo) }

      let(:embargo) do
        FactoryBot.build(:embargo, publish_at: Date.new(2020, 1, 1))
      end

      context 'with existing embargo' do
        it 'returns a list of expiry dates 3, 6 and 12 months after publish at' do
          is_expected.to match_array(
            [
              ['Choose a duration', ''],
              ['3 Months', '3_months',
               { 'data-expiry-date' => '01 April 2020' }],
              ['6 Months', '6_months',
               { 'data-expiry-date' => '01 July 2020' }],
              ['12 Months', '12_months', {
                'data-expiry-date' => '30 December 2020'
              }]
            ]
          )
        end
      end

      context 'with a different locale' do
        before { AlaveteliLocalization.set_locales(:es, :es) }

        it 'returns a localised list of expiry dates' do
          is_expected.to match_array(
            [
              ['Elija una duración', ''],
              ['3 Meses', '3_months',
               { 'data-expiry-date' => '01 abril 2020' }],
              ['6 Meses', '6_months',
               { 'data-expiry-date' => '01 julio 2020' }],
              ['12 Meses', '12_months', {
                'data-expiry-date' => '30 diciembre 2020'
              }]
            ]
          )
        end
      end
    end

    context 'without embargo' do
      subject { embargo_extension_options }

      around do |example|
        time_travel_to Time.utc(2020, 1, 2)
        example.call
        back_to_the_present
      end

      it 'returns a list of expiry dates 3, 6 and 12 months into the future' do
        is_expected.to match_array(
          [
            ['Choose a duration', ''],
            ['3 Months', '3_months',
             { 'data-expiry-date' => '02 April 2020' }],
            ['6 Months', '6_months',
             { 'data-expiry-date' => '02 July 2020' }],
            ['12 Months', '12_months', {
              'data-expiry-date' => '31 December 2020'
            }]
          ]
        )
      end
    end
  end
end
