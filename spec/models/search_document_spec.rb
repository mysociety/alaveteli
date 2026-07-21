# == Schema Information
#
# Table name: search_documents
#
#  sd_id             :bigint           not null, primary key
#  searchable_type   :string           not null, primary key
#  searchable_id     :bigint
#  raw_content       :text
#  raw_admin_content :text
#  section_ref       :text
#  language          :text
#  content_tsv       :tsvector
#  admin_content_tsv :tsvector
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'spec_helper'

RSpec.describe SearchDocument do
  let(:user) do
    FactoryBot.create(:user, name: 'Florence Nightingale',
                             about_me: 'I enjoy data visualisation')
  end

  context 'model search' do
    it 'returns a chainable ActiveRecord::Relation' do
      user.reindex
      results = User.newsearch('Florence', admin_mode: true)
      expect(results).to be_an(ActiveRecord::Relation)
      expect(results.where(email_confirmed: true).count).to eq(1)
    end

    it 'finds users by admin indexed fields' do
      user.reindex
      expect(
        User.newsearch(user.email, admin_mode: true)
      ).to match_array([user])
      expect(
        User.newsearch('data visualisation', admin_mode: true)
      ).to match_array([user])
    end

    it 'does not match admin indexed fields without admin_mode' do
      user.reindex
      expect(User.newsearch('Florence')).to match_array([])
    end

    it 'raises for models that have not been made searchable' do
      expect { Comment.newsearch('anything') }.
        to raise_error(NotImplementedError)
    end
  end
end
