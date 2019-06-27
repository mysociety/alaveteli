# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminUsersHelper do

  include AdminUsersHelper

  describe '#user_labels' do

    it 'adds no labels if the user is not noteworthy' do
      expect(user_labels(User.new)).to eq('')
    end

    it 'adds an admin label if the user is an admin' do
      user = FactoryBot.create(:admin_user)
      html = %q(<span class="label">admin</span>)
      expect(user_labels(user)).to eq(html)
    end

    it 'adds a banned label if the user is banned' do
      user = FactoryBot.create(:user, ban_text: 'Banned')
      html = %q(<span class="label label-warning">banned</span>)
      expect(user_labels(user)).to eq(html)
    end

    it 'adds a closed label if the user is banned' do
      user = FactoryBot.create(:user, closed_at: Time.zone.now)
      html = %q(<span class="label label-warning">closed</span>)
      expect(user_labels(user)).to eq(html)
    end

    it 'adds labels for all noteworthy attributes' do
      user = FactoryBot.create(:admin_user,
                               ban_text: 'Banned',
                               closed_at: Time.zone.now)
      html = %q(<span class="label label-warning">banned</span>)
      html += %q(<span class="label label-warning">closed</span>)
      html += %q(<span class="label">admin</span>)
      expect(user_labels(user)).to eq(html)
    end

  end

end
