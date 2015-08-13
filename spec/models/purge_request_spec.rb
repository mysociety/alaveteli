# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: purge_requests
#
#  id         :integer          not null, primary key
#  url        :string(255)
#  created_at :datetime         not null
#  model      :string(255)      not null
#  model_id   :integer          not null
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'fakeweb'

describe PurgeRequest, "purging things" do
  before do
    PurgeRequest.destroy_all
    FakeWeb.last_request = nil
  end

  it 'should issue purge requests to the server' do
    req = PurgeRequest.new(:url => "/begone_from_here",
                           :model => "don't care",
                           :model_id => "don't care")
    req.save
    expect(PurgeRequest.all.count).to eq(1)
    PurgeRequest.purge_all
    expect(PurgeRequest.all.count).to eq(0)
  end

  it 'should fail silently for a misconfigured server' do
    FakeWeb.register_uri(:get, %r|brokenv|, :body => "BROKEN")
    config = MySociety::Config.load_default
    config['VARNISH_HOST'] = "brokencache"
    req = PurgeRequest.new(:url => "/begone_from_here",
                           :model => "don't care",
                           :model_id => "don't care")
    req.save
    expect(PurgeRequest.all.count).to eq(1)
    PurgeRequest.purge_all
    expect(PurgeRequest.all.count).to eq(0)
  end
end
