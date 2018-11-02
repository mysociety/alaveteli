require 'spec_helper'

describe AdminRequestsHelper do

  include AdminRequestsHelper

  describe '#reason_text' do

    let(:default_text) {
      <<-EOF.squish
We consider it to be vexatious, and have therefore hidden it from other
users. You will still be able to view it while logged in to the site. Please
reply to this email if you would like to discuss this decision further.
EOF
    }

    it 'returns the default text if sent an unknown reason' do
      expect(reason_text('meh')).to eq default_text
    end

    it 'returns the correct text for "not_foi"' do
      expect(reason_text('not_foi')).
        to eq 'We consider it is not a valid FOI request, and have ' \
              'therefore hidden it from other users.'
    end

    it 'returns the correct text for "immigration_correspondence"' do
      expect(reason_text('immigration_correspondence')).
        to include 'We consider this is not a valid FOI request as it ' \
                   'contains personal correspondence relating to an ' \
                   'immigration enquiry.'
    end

  end

end
