require 'spec_helper'

RSpec.describe PaginationHelper do
  include PaginationHelper

  describe '#will_paginate_translate' do
    let(:options) {}
    subject { will_paginate_translate(key, options) }

    context 'with :previous_label key' do
      let(:key) { :previous_label }

      it { is_expected.to eq('&#8592; Previous') }

      it 'can translate into ES' do
        AlaveteliLocalization.with_locale(:es) do
          is_expected.to eq('&laquo; Anterior')
        end
      end
    end

    context 'with :next_label key' do
      let(:key) { :next_label }

      it { is_expected.to eq('Next &#8594;') }

      it 'can translate into ES' do
        AlaveteliLocalization.with_locale(:es) do
          is_expected.to eq('Siguiente &raquo;')
        end
      end
    end

    context 'with :container_aria_label key' do
      let(:key) { :container_aria_label }

      it { is_expected.to eq('Pagination') }

      it 'can translate into ES' do
        AlaveteliLocalization.with_locale(:es) do
          is_expected.to eq('Paginación')
        end
      end
    end

    context 'with :page_aria_label key' do
      let(:options) { { page: 1 } }
      let(:key) { :page_aria_label }

      it { is_expected.to eq('Page 1') }

      it 'can translate into ES' do
        AlaveteliLocalization.with_locale(:es) do
          is_expected.to eq('Página 1')
        end
      end
    end
  end
end
