# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Ability do
  describe ".can_update_request_state?" do
    context "old and unclassified request" do
      let(:request) { mock_model(InfoRequest, :is_old_unclassified? => true) }

      context "logged out" do
        let(:user) { nil }
        before(:each) { request.stub!(:is_owning_user?).and_return(false) }
        it { Ability::can_update_request_state?(user, request).should be_false }
      end

      context "logged in but not owner of request" do
        let(:user) { mock_model(User) }
        before(:each) { request.stub!(:is_owning_user?).and_return(false) }

        it { Ability::can_update_request_state?(user, request).should be_true }
      end
    end

    context "new request" do
      let(:request) { mock_model(InfoRequest, :is_old_unclassified? => false) }

      context "logged out" do
        let(:user) { nil }
        before(:each) { request.stub!(:is_owning_user?).and_return(false) }

        it { Ability::can_update_request_state?(user, request).should be_false }
      end

      context "logged in" do
        let(:user) { mock_model(User) }

        # An owner of a request can also be someone with admin powers
        context "as owner of request" do
          before(:each) { request.stub!(:is_owning_user?).and_return(true) }

          it { Ability::can_update_request_state?(user, request).should be_true }
        end

        context "but not owner of request" do
          before(:each) { request.stub!(:is_owning_user?).and_return(false) }

          it { Ability::can_update_request_state?(user, request).should be_false }
        end
      end
    end
  end
end

