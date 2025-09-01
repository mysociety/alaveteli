require 'spec_helper'

RSpec.describe User::Unused do
  it 'module is included to User' do
    expect(User.ancestors).to include(User::Unused)
  end

  describe '.unused' do
    subject { User.unused }

    let!(:unused_user) { FactoryBot.create(:user, :unused) }

    context 'when user has no activity' do
      it 'includes users with zero counters and no roles or sign-ins' do
        is_expected.to include(unused_user)
      end
    end

    context 'when user is the internal_admin_user' do
      let!(:internal_admin_user) do
        FactoryBot.create(:user, :unused, :internal_admin_user)
      end

      it 'excludes the internal admin user' do
        is_expected.not_to include(internal_admin_user)
      end
    end

    context 'when user has info requests' do
      let!(:user_with_requests) do
        FactoryBot.create(:user, :unused, info_requests_count: 1)
      end

      it 'excludes users with info_requests_count > 0' do
        is_expected.not_to include(user_with_requests)
      end
    end

    context 'when user has info request batches' do
      let!(:user_with_batches) do
        FactoryBot.create(:user, :unused, info_request_batches_count: 1)
      end

      it 'excludes users with info_request_batches_count > 0' do
        is_expected.not_to include(user_with_batches)
      end
    end

    context 'when user has played classification game' do
      let!(:user_with_request_classifications) do
        FactoryBot.create(:user, :unused, request_classifications_count: 1)
      end

      it 'excludes users with request_classifications_count > 0' do
        is_expected.not_to include(user_with_request_classifications)
      end
    end

    context 'when user has classified requests' do
      let!(:user_with_classifications) do
        FactoryBot.create(:user, :unused, status_update_count: 1)
      end

      it 'excludes users with status_update_count > 0' do
        is_expected.not_to include(user_with_classifications)
      end
    end

    context 'when user has tracked things' do
      let!(:user_with_tracks) do
        FactoryBot.create(:user, :unused, track_things_count: 1)
      end

      it 'excludes users with track_things_count > 0' do
        is_expected.not_to include(user_with_tracks)
      end
    end

    context 'when user has comments' do
      let!(:user_with_comments) do
        FactoryBot.create(:user, :unused, comments_count: 1)
      end

      it 'excludes users with comments_count > 0' do
        is_expected.not_to include(user_with_comments)
      end
    end

    context 'when user public body change requests' do
      let!(:user_with_change_request) do
        FactoryBot.create(:user, :unused, public_body_change_requests_count: 1)
      end

      it 'excludes users with public_body_change_requests_count > 0' do
        is_expected.not_to include(user_with_change_request)
      end
    end

    context 'when user has citations' do
      let!(:user_with_citations) { FactoryBot.create(:user, :unused) }

      before do
        FactoryBot.create(:citation, user: user_with_citations)
      end

      it 'excludes users with citations' do
        is_expected.not_to include(user_with_citations)
      end
    end

    context 'when user with certain roles' do
      let!(:admin_user) { FactoryBot.create(:admin_user, :unused) }
      let!(:pro_user) { FactoryBot.create(:pro_user, :unused) }
      let!(:pro_admin_user) { FactoryBot.create(:pro_admin_user, :unused) }

      it 'excludes admin users' do
        is_expected.not_to include(admin_user)
      end

      it 'excludes pro users' do
        is_expected.not_to include(pro_user)
      end

      it 'excludes pro admin users' do
        is_expected.not_to include(pro_admin_user)
      end
    end

    context 'when user has submitted to a project' do
      let!(:contributor) { FactoryBot.create(:user, :unused) }

      before do
        FactoryBot.create(:project_submission, user: contributor)
      end

      it 'excludes users who have submitted to a project' do
        is_expected.not_to include(contributor)
      end
    end

    context 'when user has recent sign-ins' do
      let!(:user_with_signin) { FactoryBot.create(:user, :unused) }

      before do
        allow(AlaveteliConfiguration).
          to receive(:user_sign_in_activity_retention_days).and_return(1)
        FactoryBot.create(:user_sign_in, user: user_with_signin)
      end

      it 'excludes users with sign-ins' do
        is_expected.not_to include(user_with_signin)
      end
    end

    it 'returns an ActiveRecord::Relation' do
      is_expected.to be_a(ActiveRecord::Relation)
    end

    it 'is chainable with other scopes' do
      FactoryBot.create(:user, :unused)
      FactoryBot.create(:user, :unused, :banned)

      expect(subject.banned).to have_attributes(count: 1)
    end
  end
end
