require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "cancan/matchers"

shared_examples_for "a class with message prominence" do
  let(:admin_ability) { Ability.new(FactoryGirl.create(:admin_user)) }
  let(:other_user_ability) { Ability.new(FactoryGirl.create(:user)) }

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
    let(:info_request) { FactoryGirl.create(:info_request_with_incoming) }
    let!(:resource) { info_request.incoming_messages.first }
    let!(:owner_ability) { Ability.new(info_request.user) }

    it_behaves_like "a class with message prominence"
  end

  describe "reading OutgoingMessages" do
    let(:info_request) { FactoryGirl.create(:info_request) }
    let!(:resource) { info_request.outgoing_messages.first }
    let!(:owner_ability) { Ability.new(info_request.user) }

    it_behaves_like "a class with message prominence"
  end

  describe "reading InfoRequests" do
    let!(:resource) { FactoryGirl.create(:info_request) }
    let!(:owner_ability) { Ability.new(resource.user) }

    it_behaves_like "a class with message prominence"
  end

  describe "updating request state of InfoRequests" do
    context "given an old and unclassified request" do
      let(:request) { FactoryGirl.create(:old_unclassified_request) }

      before do
        allow(request).to receive(:is_old_unclassified?).and_return(true)
      end

      context "when logged out" do
        let(:ability) { Ability.new(nil) }

        it "should return false" do
          expect(ability).not_to be_able_to(:update_request_state, request)
        end
      end

      context "when logged in but not owner of request" do
        let(:user) { FactoryGirl.create(:user) }
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
      let(:request) { FactoryGirl.create(:info_request) }

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
          let(:ability) { Ability.new(FactoryGirl.create(:admin_user)) }

          it "should return true" do
            expect(ability).to be_able_to(:update_request_state, request)
          end
        end

        context "but not owner of request" do
          let(:ability) { Ability.new(FactoryGirl.create(:user)) }

          it "should return false" do
            expect(ability).not_to be_able_to(:update_request_state, request)
          end
        end
      end
    end
  end
end