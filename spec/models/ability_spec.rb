require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "cancan/matchers"

shared_examples_for "a class with message prominence" do
  let(:admin_ability) { Ability.new(FactoryBot.create(:admin_user)) }
  let(:other_user_ability) { Ability.new(FactoryBot.create(:user)) }

  context 'if the prominence is hidden' do
    before do
      resource.prominence = 'hidden'
    end

    it 'should return true for an admin user' do
      expect(admin_ability).to be_able_to(:read, resource)
    end

    it 'should return false for a non-admin user' do
      expect(other_user_ability).not_to be_able_to(:read, resource)
    end

    it 'should return false for the owner' do
      expect(owner_ability).not_to be_able_to(:read, resource)
    end
  end

  context 'if the prominence is requester_only' do
    before do
      resource.prominence = 'requester_only'
    end

    it 'should return true if the user owns the right resource' do
      expect(owner_ability).to be_able_to(:read, resource)
    end

    it 'should return true for an admin user' do
      expect(admin_ability).to be_able_to(:read, resource)
    end

    it 'should return false if the user does not own the right resource' do
      expect(other_user_ability).not_to be_able_to(:read, resource)
    end
  end

  context 'if the prominence is normal' do
    before do
      resource.prominence = 'normal'
    end

    it 'should return true for a non-admin user' do
      expect(other_user_ability).to be_able_to(:read, resource)
    end

    it 'should return true for an admin user' do
      expect(admin_ability).to be_able_to(:read, resource)
    end

    it 'should return true if the user owns the right resource' do
      expect(owner_ability).to be_able_to(:read, resource)
    end
  end
end

describe Ability do
  describe "reading IncomingMessages" do
    let(:info_request) { FactoryBot.create(:info_request_with_incoming) }
    let!(:resource) { info_request.incoming_messages.first }
    let!(:owner_ability) { Ability.new(info_request.user) }

    it_behaves_like "a class with message prominence"
  end

  describe "reading OutgoingMessages" do
    let(:info_request) { FactoryBot.create(:info_request) }
    let!(:resource) { info_request.outgoing_messages.first }
    let!(:owner_ability) { Ability.new(info_request.user) }

    it_behaves_like "a class with message prominence"
  end

  describe "reading InfoRequests" do
    let!(:resource) { FactoryBot.create(:info_request) }
    let!(:owner_ability) { Ability.new(resource.user) }

    it_behaves_like "a class with message prominence"

    context 'when the request is embargoed' do
      let!(:resource) { FactoryBot.create(:embargoed_request) }
      let(:admin_ability) { Ability.new(FactoryBot.create(:admin_user)) }
      let(:pro_admin_ability) { Ability.new(FactoryBot.create(:pro_admin_user)) }
      let(:other_user_ability) { Ability.new(FactoryBot.create(:user)) }

      context 'if the prominence is hidden' do
        before do
          resource.prominence = 'hidden'
        end

        it 'should return false for an admin user' do
          expect(admin_ability).not_to be_able_to(:read, resource)
        end

        context 'with pro enabled' do

          it 'should return false for an admin user' do
            with_feature_enabled(:alaveteli_pro) do
              expect(admin_ability).not_to be_able_to(:read, resource)
            end
          end

          it 'should return true for a pro admin user' do
            with_feature_enabled(:alaveteli_pro) do
              expect(pro_admin_ability).to be_able_to(:read, resource)
            end
          end
        end

        it 'should return false for a non-admin user' do
          expect(other_user_ability).not_to be_able_to(:read, resource)
        end

        it 'should return false for the owner' do
          expect(owner_ability).not_to be_able_to(:read, resource)
        end
      end

      context 'if the prominence is requester_only' do
        before do
          resource.prominence = 'requester_only'
        end

        it 'should return true if the user owns the right resource' do
          expect(owner_ability).to be_able_to(:read, resource)
        end

        it 'should return false for an admin user' do
          expect(admin_ability).not_to be_able_to(:read, resource)
        end

        context 'with pro enabled' do

          it 'should return false for an admin user' do
            with_feature_enabled(:alaveteli_pro) do
              expect(admin_ability).not_to be_able_to(:read, resource)
            end
          end

          it 'should return true for a pro admin user' do
            with_feature_enabled(:alaveteli_pro) do
              expect(pro_admin_ability).to be_able_to(:read, resource)
            end
          end

        end

        it 'should return false if the user does not own the right resource' do
          expect(other_user_ability).not_to be_able_to(:read, resource)
        end
      end

      context 'if the prominence is normal' do
        before do
          resource.prominence = 'normal'
        end

        it 'should return false for a non-admin user' do
          expect(other_user_ability).not_to be_able_to(:read, resource)
        end

        it 'should return false for an admin user' do
          expect(admin_ability).not_to be_able_to(:read, resource)
        end

        context 'with pro enabled' do

          it 'should return false for an admin user' do
            with_feature_enabled(:alaveteli_pro) do
              expect(admin_ability).not_to be_able_to(:read, resource)
            end
          end

          it 'should return true for a pro admin user' do
            with_feature_enabled(:alaveteli_pro) do
              expect(pro_admin_ability).to be_able_to(:read, resource)
            end
          end

        end

        context 'with public token' do
          let(:admin_ability) do
            Ability.new(FactoryBot.create(:admin_user), public_token: true)
          end

          let(:pro_admin_ability) do
            Ability.new(FactoryBot.create(:pro_admin_user), public_token: true)
          end

          let(:other_user_ability) do
            Ability.new(FactoryBot.create(:user), public_token: true)
          end

          it 'should return true for an admin user' do
            expect(admin_ability).to be_able_to(:read, resource)
          end

          it 'should return true for a pro admin user' do
            expect(pro_admin_ability).to be_able_to(:read, resource)
          end

          it 'should return true for a non-admin user' do
            expect(other_user_ability).to be_able_to(:read, resource)
          end
        end

        it 'should return true if the user owns the right resource' do
          expect(owner_ability).to be_able_to(:read, resource)
        end
      end

    end

  end

  describe 'sharing InfoRequests' do
    let(:request) { FactoryBot.build(:info_request) }

    context 'when logged out' do
      let(:ability) { Ability.new(nil) }

      it 'should return false' do
        expect(ability).not_to be_able_to(:share, request)
      end
    end

    context 'when the request is embargoed' do
      let(:request) { FactoryBot.create(:embargoed_request) }
      let(:ability) { Ability.new(user) }

      context 'as request owner' do
        let(:user) { request.user }

        it 'should return true' do
          expect(ability).to be_able_to(:share, request)
        end

        it 'without a public_token, should return false' do
          request.public_token = nil
          expect(ability).not_to be_able_to(:share, request)
        end
      end

      context 'as another user' do
        let(:user) { FactoryBot.create(:user) }

        it 'should return false' do
          expect(ability).not_to be_able_to(:share, request)
        end
      end

      context 'as an Pro admin' do
        let(:user) { FactoryBot.create(:pro_admin_user) }

        it 'should return true' do
          expect(ability).to be_able_to(:share, request)
        end
      end

      context 'as an admin' do
        let(:user) { FactoryBot.create(:admin_user) }

        it 'should return false' do
          expect(ability).not_to be_able_to(:share, request)
        end
      end
    end

    context 'when the request is public' do
      let(:ability) { Ability.new(user) }

      context 'as request owner' do
        let(:user) { request.user }

        it 'should return false' do
          expect(ability).not_to be_able_to(:share, request)
        end
      end

      context 'as another user' do
        let(:user) { FactoryBot.create(:user) }

        it 'should return false' do
          expect(ability).not_to be_able_to(:share, request)
        end
      end

      context 'as an Pro admin' do
        let(:user) { FactoryBot.create(:pro_admin_user) }

        it 'should return false' do
          expect(ability).not_to be_able_to(:share, request)
        end
      end

      context 'as an admin' do
        let(:user) { FactoryBot.create(:admin_user) }

        it 'should return false' do
          expect(ability).not_to be_able_to(:share, request)
        end
      end
    end
  end

  describe "updating request state of InfoRequests" do
    context "given an old and unclassified request" do
      let(:request) { FactoryBot.create(:old_unclassified_request) }

      context "when logged out" do
        let(:ability) { Ability.new(nil) }

        it "should return false" do
          expect(ability).not_to be_able_to(:update_request_state, request)
        end
      end

      context "when logged in but not owner of request" do
        let(:user) { FactoryBot.create(:user) }
        let(:ability) { Ability.new(user) }

        it "should return true" do
          expect(ability).to be_able_to(:update_request_state, request)
        end
      end

      context "when owner of request" do
        let(:user) { request.user }
        let(:ability) { Ability.new(user) }

        it "should return true" do
          expect(ability).to be_able_to(:update_request_state, request)
        end
      end
    end

    context "given a new request" do
      let(:request) { FactoryBot.create(:info_request) }

      context "when logged out" do
        let(:ability) { Ability.new(nil) }

        it "should return false" do
          expect(ability).not_to be_able_to(:update_request_state, request)
        end
      end

      context "when logged in" do
        context "as owner of request" do
          let(:ability) { Ability.new(request.user) }

          it "should return true" do
            expect(ability).to be_able_to(:update_request_state, request)
          end
        end

        context "as an admin" do
          let(:ability) { Ability.new(FactoryBot.create(:admin_user)) }

          it "should return true" do
            expect(ability).to be_able_to(:update_request_state, request)
          end
        end

        context "but not owner of request" do
          let(:ability) { Ability.new(FactoryBot.create(:user)) }

          it "should return false" do
            expect(ability).not_to be_able_to(:update_request_state, request)
          end
        end
      end
    end
  end

  describe "reading InfoRequestBatches" do
    let(:admin_ability) { Ability.new(FactoryBot.create(:admin_user)) }
    let(:pro_admin_ability) { Ability.new(FactoryBot.create(:pro_admin_user)) }
    let(:pro_user_ability) { Ability.new(FactoryBot.create(:pro_user)) }
    let(:other_user_ability) { Ability.new(FactoryBot.create(:user)) }

    context "when the batch is embargoed" do
      let(:resource) { FactoryBot.create(:info_request_batch, :embargoed) }

      context "when the user owns the batch" do
        let(:ability) { Ability.new(resource.user) }

        it "should return true" do
          with_feature_enabled(:alaveteli_pro) do
            expect(ability).to be_able_to(:read, resource)
          end
        end
      end

      context "when the user is a pro_admin" do
        it "should return true" do
          with_feature_enabled(:alaveteli_pro) do
            expect(pro_admin_ability).to be_able_to(:read, resource)
          end
        end
      end

      context "when the user is an admin" do
        it "should return false" do
          with_feature_enabled(:alaveteli_pro) do
            expect(admin_ability).not_to be_able_to(:read, resource)
          end
        end
      end

      context "when the user is a pro but doesn't own the batch" do
        it "should return false" do
          with_feature_enabled(:alaveteli_pro) do
            expect(pro_user_ability).not_to be_able_to(:read, resource)
          end
        end
      end

      context "when the user is a normal user" do
        it "should return false" do
          with_feature_enabled(:alaveteli_pro) do
            expect(other_user_ability).not_to be_able_to(:read, resource)
          end
        end
      end
    end

    context "when the batch is not embargoed" do
      let(:resource) { FactoryBot.create(:info_request_batch) }
      let(:all_the_abilities) do
        [
          admin_ability,
          pro_admin_ability,
          pro_user_ability,
          other_user_ability,
          Ability.new(resource.user),
          Ability.new(nil) # Even an anon user should be able to read it
        ]
      end

      it "should always return true" do
        all_the_abilities.each do |ability|
          expect(ability).to be_able_to(:read, resource)
        end
      end
    end
  end

  describe "updating InfoRequestBatches" do
    let(:admin_ability) { Ability.new(FactoryBot.create(:admin_user)) }
    let(:pro_admin_ability) { Ability.new(FactoryBot.create(:pro_admin_user)) }
    let(:pro_user_ability) { Ability.new(FactoryBot.create(:pro_user)) }
    let(:other_user_ability) { Ability.new(FactoryBot.create(:user)) }

    context "when the batch is embargoed" do
      let(:resource) do
        FactoryBot.create(:info_request_batch, :embargoed,
                          user: FactoryBot.create(:pro_user))
      end

      context "when the user owns the batch" do

        it 'allows pro users to update the batch' do
          ability = Ability.new(resource.user)
          with_feature_enabled(:alaveteli_pro) do
            expect(ability).to be_able_to(:update, resource)
          end
        end

        it 'does not allow non-pro users to update the batch' do
          resource.user.remove_role(:pro)
          ability = Ability.new(resource.user)
          with_feature_enabled(:alaveteli_pro) do
            expect(ability).not_to be_able_to(:update, resource)
          end
        end

      end

      context "when the user is a pro_admin" do
        it "should return true" do
          with_feature_enabled(:alaveteli_pro) do
            expect(pro_admin_ability).to be_able_to(:update, resource)
          end
        end
      end

      context "when the user is an admin" do
        it "should return false" do
          with_feature_enabled(:alaveteli_pro) do
            expect(admin_ability).not_to be_able_to(:update, resource)
          end
        end
      end

      context "when the user is a pro but doesn't own the batch" do
        it "should return false" do
          with_feature_enabled(:alaveteli_pro) do
            expect(pro_user_ability).not_to be_able_to(:update, resource)
          end
        end
      end

      context "when the user is a normal user" do
        it "should return false" do
          with_feature_enabled(:alaveteli_pro) do
            expect(other_user_ability).not_to be_able_to(:update, resource)
          end
        end
      end
    end

    context "when the batch is not embargoed" do
      let(:resource) { FactoryBot.create(:info_request_batch) }

      context "when the user owns the batch" do
        let(:ability) { Ability.new(resource.user) }

        it "should return true" do
          with_feature_enabled(:alaveteli_pro) do
            expect(ability).to be_able_to(:update, resource)
          end
        end
      end

      context "when the user is a pro_admin" do
        it "should return true" do
          with_feature_enabled(:alaveteli_pro) do
            expect(pro_admin_ability).to be_able_to(:update, resource)
          end
        end
      end

      context "when the user is an admin" do
        it "should return true" do
          with_feature_enabled(:alaveteli_pro) do
            expect(admin_ability).to be_able_to(:update, resource)
          end
        end
      end

      context "when the user is a pro but doesn't own the batch" do
        it "should return false" do
          with_feature_enabled(:alaveteli_pro) do
            expect(pro_user_ability).not_to be_able_to(:update, resource)
          end
        end
      end

      context "when the user is a normal user" do
        it "should return false" do
          with_feature_enabled(:alaveteli_pro) do
            expect(other_user_ability).not_to be_able_to(:update, resource)
          end
        end
      end
    end
  end

  describe "accessing Alaveteli Pro" do
    subject(:ability) { Ability.new(user) }

    context "when the user is a pro" do
      let(:user) { FactoryBot.create(:pro_user) }
      it "should return true" do
        with_feature_enabled(:alaveteli_pro) do
          expect(ability).to be_able_to(:access, :alaveteli_pro)
        end
      end
    end

    context "when the user is an admin" do
      let(:user) { FactoryBot.create(:admin_user) }

      it "should return false" do
        with_feature_enabled(:alaveteli_pro) do
          expect(ability).not_to be_able_to(:access, :alaveteli_pro)
        end
      end
    end

    context "when the user is a pro admin" do
      let(:user) { FactoryBot.create(:pro_admin_user) }

      it "should return true" do
        with_feature_enabled(:alaveteli_pro) do
          expect(ability).to be_able_to(:access, :alaveteli_pro)
        end
      end
    end

    context "when the user is a normal user" do
      let(:user) { FactoryBot.create(:user) }

      it "should return false" do
        with_feature_enabled(:alaveteli_pro) do
          expect(ability).not_to be_able_to(:access, :alaveteli_pro)
        end
      end
    end

    context "when the user is nil" do
      let(:user) { nil }

      it "should return false" do
        with_feature_enabled(:alaveteli_pro) do
          expect(ability).not_to be_able_to(:access, :alaveteli_pro)
        end
      end
    end
  end

  describe "Creating Embargoes" do
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

    context 'the info request owner is a pro user' do
      let(:user) { FactoryBot.create(:pro_user) }
      let(:info_request) { FactoryBot.create(:info_request, user: user) }

      it 'allows the request owner to add an embargo' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(info_request.user)
          expect(ability).to be_able_to(:create_embargo, info_request)
        end

      end

      it "allows pro admins to add an embargo" do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_admin_user)
          expect(ability).to be_able_to(:create_embargo, info_request)
        end
      end

      context 'the info request is part of a batch' do
        let(:batch_request) do
          batch = FactoryBot.create(:info_request_batch, user: user)
          request = FactoryBot.create(:info_request, title: batch.title,
                                                     user: batch.user)
          batch.info_requests << request
          batch.info_requests.first
        end

        it 'does not allow the request owner to add an embargo' do
          with_feature_enabled(:alaveteli_pro) do
            ability = Ability.new(batch_request.user)
            expect(ability).to_not be_able_to(:create_embargo, batch_request)
          end
        end

      end

    end

    context 'the info request owner is not a pro user' do
      let(:user) { FactoryBot.create(:pro_user) }
      let(:info_request) { FactoryBot.create(:info_request, user: user) }

      before do
        user.remove_role(:pro)
      end

      it 'prevents the request owner from adding an embargo' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(user)
          expect(ability).not_to be_able_to(:create_embargo, info_request)
        end

      end

      it "prevents pro admins adding an embargo" do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_admin_user)
          expect(ability).not_to be_able_to(:create_embargo, info_request)
        end
      end

    end

    context 'the info request was made anonymously', feature: :alaveteli_pro do
      let(:info_request) { FactoryBot.build(:external_request) }

      it 'prevents user from adding an embargo' do
        ability = Ability.new(FactoryBot.create(:user))
        expect(ability).not_to be_able_to(:create_embargo, info_request)
      end

      it 'prevents admin from adding an embargo' do
        ability = Ability.new(FactoryBot.create(:admin_user))
        expect(ability).not_to be_able_to(:create_embargo, info_request)
      end

      it 'prevents pro admin from adding an embargo' do
        ability = Ability.new(FactoryBot.create(:pro_admin_user))
        expect(ability).not_to be_able_to(:create_embargo, info_request)
      end

    end

  end

  describe "Updating Embargoes" do

    let(:embargo) do
      FactoryBot.create(:embargo, user: FactoryBot.create(:pro_user))
    end

    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

    it "allows pro info request owners to update it" do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(embargo.info_request.user)
        expect(ability).to be_able_to(:update, embargo)
      end
    end

    it "doesn't allow non-pro info request owners to update it" do
      embargo.info_request.user.remove_role(:pro)

      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(embargo.info_request.user)
        expect(ability).not_to be_able_to(:update, embargo)
      end
    end

    it "allows pro admins to update it" do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(pro_admin_user)
        expect(ability).to be_able_to(:update, embargo)
      end
    end

    it "doesn't allow admins to update it" do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(admin_user)
        expect(ability).not_to be_able_to(:update, embargo)
      end
    end

    it "doesnt allow anonymous users to update it" do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(nil)
        expect(ability).not_to be_able_to(:update, embargo)
      end
    end

    it "doesnt allow other users to update it" do
      other_user = FactoryBot.create(:user)
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(other_user)
        expect(ability).not_to be_able_to(:update, embargo)
      end
    end
  end

  describe "Destroying Embargoes" do

    let(:embargo) do
      FactoryBot.create(:embargo, user: FactoryBot.create(:pro_user))
    end

    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

    it 'allows a pro info request owner to destroy it' do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(embargo.info_request.user)
        expect(ability).to be_able_to(:destroy, embargo)
      end
    end

    it 'allows a non-pro info request owner to destroy it' do
      with_feature_enabled(:alaveteli_pro) do
        embargo.info_request.user.remove_role(:pro)
        ability = Ability.new(embargo.info_request.user)
        expect(ability).to be_able_to(:destroy, embargo)
      end
    end

    it "allows pro admins to destroy it" do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(pro_admin_user)
        expect(ability).to be_able_to(:destroy, embargo)
      end
    end

    it "doesn't allow admins to destroy it" do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(admin_user)
        expect(ability).not_to be_able_to(:destroy, embargo)
      end
    end

    it "doesnt allow anonymous users to destroy it" do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(nil)
        expect(ability).not_to be_able_to(:destroy, embargo)
      end
    end

    it "doesnt allow other users to destroy it" do
      other_user = FactoryBot.create(:user)
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(other_user)
        expect(ability).not_to be_able_to(:destroy, embargo)
      end
    end

  end

  describe "Destroying Batch Embargoes" do

    let(:batch) do
      FactoryBot.create(:info_request_batch, :embargoed,
                        user: FactoryBot.create(:pro_user))
    end

    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

    it 'allows a pro info batch owner to destroy it' do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(batch.user)
        expect(ability).to be_able_to(:destroy_embargo, batch)
      end
    end

    it 'allows a non-pro info request owner to destroy it' do
      with_feature_enabled(:alaveteli_pro) do
        batch.user.remove_role(:pro)
        ability = Ability.new(batch.user)
        expect(ability).to be_able_to(:destroy_embargo, batch)
      end
    end

    it "allows pro admins to destroy it" do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(pro_admin_user)
        expect(ability).to be_able_to(:destroy_embargo, batch)
      end
    end

    it "doesn't allow admins to destroy it" do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(admin_user)
        expect(ability).not_to be_able_to(:destroy_embargo, batch)
      end
    end

    it "doesnt allow anonymous users to destroy it" do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(nil)
        expect(ability).not_to be_able_to(:destroy_embargo, batch)
      end
    end

    it "doesnt allow other users to destroy it" do
      other_user = FactoryBot.create(:user)
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(other_user)
        expect(ability).not_to be_able_to(:destroy_embargo, batch)
      end
    end

  end

  describe "Logging in as a user" do
    let(:user) { FactoryBot.create(:user) }
    let(:pro_user) { FactoryBot.create(:pro_user) }
    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

    context 'when the user has no roles' do

      it 'allows an admin user to login as them' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(admin_user)
          expect(ability).to be_able_to(:login_as, user)
        end
      end

      it 'does not allow a pro user to login as them' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_user)
          expect(ability).not_to be_able_to(:login_as, user)
        end
      end

      it 'does not allow user with no roles to login as them' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(FactoryBot.create(:user))
          expect(ability).not_to be_able_to(:login_as, user)
        end
      end

      it 'does not allow them to login as themselves' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(user)
          expect(ability).not_to be_able_to(:login_as, user)
        end
      end

    end

    context 'when the user is an admin' do

      it 'allows an admin user to login as them' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(FactoryBot.create(:admin_user))
          expect(ability).to be_able_to(:login_as, admin_user)
        end
      end

      it 'does not allow them to login as themselves' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(admin_user)
          expect(ability).not_to be_able_to(:login_as, admin_user)
        end
      end

      it 'does not allow a pro user to login as them' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_user)
          expect(ability).not_to be_able_to(:login_as, admin_user)
        end
      end

      it 'does not allow user with no roles to login as them' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(user)
          expect(ability).not_to be_able_to(:login_as, admin_user)
        end
      end

    end

    context 'when the user is a pro' do

     it 'does not allow an admin user to login as them' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(admin_user)
          expect(ability).not_to be_able_to(:login_as, pro_user)
        end
      end

     it 'does not allow a pro user to login as them' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(FactoryBot.create(:pro_user))
          expect(ability).not_to be_able_to(:login_as, pro_user)
        end
      end

     it 'does not allow them to login as themselves' do
       with_feature_enabled(:alaveteli_pro) do
         ability = Ability.new(pro_user)
         expect(ability).not_to be_able_to(:login_as, pro_user)
       end
     end

     it 'does not allow user with no roles to login as them' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(user)
          expect(ability).not_to be_able_to(:login_as, pro_user)
        end
      end

     it 'allows a pro admin user to login as them' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_admin_user)
          expect(ability).to be_able_to(:login_as, pro_user)
        end
      end

    end

    context 'when the user is a pro_admin user' do

      it 'does not allow an admin user to login as them' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(admin_user)
          expect(ability).not_to be_able_to(:login_as, pro_admin_user)
        end
      end

      it 'does not allow a pro user to login as them' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_user)
          expect(ability).not_to be_able_to(:login_as, pro_admin_user)
        end
      end

      it 'does not allow user with no roles to login as them' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(user)
          expect(ability).not_to be_able_to(:login_as, pro_admin_user)
        end
      end

      it 'allows a pro admin user to login as them' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(FactoryBot.create(:pro_admin_user))
          expect(ability).to be_able_to(:login_as, pro_admin_user)
        end
      end

      it 'does not allow them to login as themselves' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_admin_user)
          expect(ability).not_to be_able_to(:login_as, pro_admin_user)
        end
      end
    end
  end

  describe 'administering requests' do
    let(:user) { FactoryBot.create(:user) }
    let(:pro_user) { FactoryBot.create(:pro_user) }
    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

    context 'when the request is embargoed' do
      let(:info_request) { FactoryBot.create(:embargoed_request) }

      it 'allows a pro admin user to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_admin_user)
          expect(ability).to be_able_to(:admin, info_request)
        end
      end

      it 'does not allow an admin to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(admin_user)
          expect(ability).not_to be_able_to(:admin, info_request)
        end
      end

      it 'does not allow a pro user to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_user)
          expect(ability).not_to be_able_to(:admin, info_request)
        end
      end

      it 'does not allow a user with no roles to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(user)
          expect(ability).not_to be_able_to(:admin, info_request)
        end
      end

      it 'does not allow no user to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(nil)
          expect(ability).not_to be_able_to(:admin, info_request)
        end
      end

    end

    context 'when the request is not embargoed' do
      let(:info_request) { FactoryBot.create(:info_request) }

      it 'allows a pro admin user to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_admin_user)
          expect(ability).to be_able_to(:admin, info_request)
        end
      end

      it 'does allow an admin to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(admin_user)
          expect(ability).to be_able_to(:admin, info_request)
        end
      end

      it 'does not allow a pro user to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_user)
          expect(ability).not_to be_able_to(:admin, info_request)
        end
      end

      it 'does not allow a user with no roles to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(user)
          expect(ability).not_to be_able_to(:admin, info_request)
        end
      end

      it 'does not allow no user to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(nil)
          expect(ability).not_to be_able_to(:admin, info_request)
        end
      end
    end

  end

  describe 'administering comments' do
    let(:user) { FactoryBot.create(:user) }
    let(:pro_user) { FactoryBot.create(:pro_user) }
    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

    context "when the comment's request is embargoed" do
      let(:info_request) { FactoryBot.create(:embargoed_request) }
      let(:comment) { FactoryBot.create(:comment,
                                       :info_request => info_request) }

      it 'allows a pro admin user to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_admin_user)
          expect(ability).to be_able_to(:admin, comment)
        end
      end

      it 'does not allow an admin to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(admin_user)
          expect(ability).not_to be_able_to(:admin, comment)
        end
      end

      it 'does not allow a pro user to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_user)
          expect(ability).not_to be_able_to(:admin, comment)
        end
      end

      it 'does not allow a user with no roles to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(user)
          expect(ability).not_to be_able_to(:admin, comment)
        end
      end

      it 'does not allow no user to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(nil)
          expect(ability).not_to be_able_to(:admin, comment)
        end
      end

    end

    context 'when the request is not embargoed' do
      let(:info_request) { FactoryBot.create(:info_request) }
      let(:comment) { FactoryBot.create(:comment,
                                       :info_request => info_request) }

      it 'allows a pro admin user to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_admin_user)
          expect(ability).to be_able_to(:admin, comment)
        end
      end

      it 'does allows an admin to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(admin_user)
          expect(ability).to be_able_to(:admin, comment)
        end
      end

      it 'does not allow a pro user to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_user)
          expect(ability).not_to be_able_to(:admin, comment)
        end
      end

      it 'does not allow a user with no roles to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(user)
          expect(ability).not_to be_able_to(:admin, comment)
        end
      end

      it 'does not allow no user to administer' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(nil)
          expect(ability).not_to be_able_to(:admin, comment)
        end
      end
    end
  end

  describe 'administering embargoes' do
    let(:user) { FactoryBot.create(:user) }
    let(:pro_user) { FactoryBot.create(:pro_user) }
    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

    it 'allows a pro admin user to administer' do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(pro_admin_user)
        expect(ability).to be_able_to(:admin, AlaveteliPro::Embargo)
      end
    end

    it 'does not allow an admin to administer' do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(admin_user)
        expect(ability).not_to be_able_to(:admin, AlaveteliPro::Embargo)
      end
    end

    it 'does not allow a pro user to administer' do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(pro_user)
        expect(ability).not_to be_able_to(:admin, AlaveteliPro::Embargo)
      end
    end

    it 'does not allow a user with no roles to administer' do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(user)
        expect(ability).not_to be_able_to(:admin, AlaveteliPro::Embargo)
      end
    end

    it 'does not allow no user to administer' do
      with_feature_enabled(:alaveteli_pro) do
        ability = Ability.new(nil)
        expect(ability).not_to be_able_to(:admin, AlaveteliPro::Embargo)
      end
    end

  end

  describe 'reading API keys' do
    let(:user) { FactoryBot.create(:user) }
    let(:pro_user) { FactoryBot.create(:pro_user) }
    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

    context 'if pro is not enabled' do

      it 'allows an admin user to read' do
        ability = Ability.new(admin_user)
        expect(ability).to be_able_to(:read, :api_key)
      end

      it 'does not allow a pro user to read' do
        ability = Ability.new(pro_user)
        expect(ability).not_to be_able_to(:read, :api_key)
      end

      it 'does not allow a user with no roles to read' do
        ability = Ability.new(user)
        expect(ability).not_to be_able_to(:read, :api_key)
      end

      it 'does not allow no user to read' do
        ability = Ability.new(nil)
        expect(ability).not_to be_able_to(:read, :api_key)
      end

    end

    context 'if pro is enabled' do

      it 'allows a pro admin user to read' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_admin_user)
          expect(ability).to be_able_to(:read, :api_key)
        end
      end

      it 'does not allow a pro user to read' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(pro_user)
          expect(ability).not_to be_able_to(:read, :api_key)
        end
      end

      it 'does not allow an admin user to read' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(admin_user)
          expect(ability).not_to be_able_to(:read, :api_key)
        end
      end

      it 'does not allow a user with no roles to read' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(user)
          expect(ability).not_to be_able_to(:read, :api_key)
        end
      end

      it 'does not allow no user to read' do
        with_feature_enabled(:alaveteli_pro) do
          ability = Ability.new(nil)
          expect(ability).not_to be_able_to(:read, :api_key)
        end
      end

    end

  end
end
