# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::BatchRequestAuthoritySearchesHelper do

  include AlaveteliPro::BatchRequestAuthoritySearchesHelper

  describe '#batch_notes_allowed_tags' do

    it 'returns the list of allowed tags' do
      allowed_tags = %w(strong em b i p code tt samp kbd var sub sup dfn cite
                        big small address hr br div span ul ol li dl dt dd abbr
                        acronym a del ins table tr td)
      expect(batch_notes_allowed_tags).to eq(allowed_tags)
    end

  end

end
