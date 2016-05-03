# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'spam_accounts_finder'

describe SpamAccountsFinder do
  include SpamAccountsFinder

  let(:spam_user_1) do
    FactoryGirl.create(:user, :about_me => "http://example.com/spam")
  end

  let(:spam_user_2) do
    FactoryGirl.create(:user, :about_me => %Q|
      I have included text and http://example.com/spam a couple of links
      http://example.com/spam2
    |)
  end

  let(:not_spam) { FactoryGirl.create(:user, :about_me => "hi!") }

  let(:banned) do
    FactoryGirl.create(:user, :about_me => "http://example.com/spam",
                       :ban_text => "Banned")
  end

  describe ".potential_spammers" do

    it "includes accounts with profile links" do
      expect(potential_spammers).to include(spam_user_1, spam_user_2)
    end

    it "excludes accounts which have already been banned" do
      expect(potential_spammers).not_to include(banned)
    end

    it "does not include accounts with no profile links" do
      expect(potential_spammers).not_to include(not_spam)
    end

  end

  describe ".extract_links" do

    it "returns an array containing the profile link" do
      expect(extract_links(spam_user_1.about_me)).
        to eq(["http://example.com/spam"])
    end

    it "returns all the links, not just the first one" do
      expect(extract_links(spam_user_2.about_me)).
        to eq(["http://example.com/spam", "http://example.com/spam2"])
    end

    it "copes with https links" do
      expect(extract_links("https://example.com/spam")).
        to eq(["https://example.com/spam"])
    end

  end

end
