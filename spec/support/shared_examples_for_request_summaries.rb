# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for "RequestSummaries" do
  let(:model) { described_class }
  let(:class_name) { model.to_s }
  let(:factory) { class_name.demodulize.underscore }

  it "calls create_or_update_request_summary on create" do
    resource = FactoryGirl.build(factory)
    expect(resource).to receive(:create_or_update_request_summary)
    resource.save!
  end

  it "calls create_or_update_request_summary on update" do
    resource = FactoryGirl.create(factory)
    expect(resource).to receive(:create_or_update_request_summary)
    resource.save!
  end

  it "deletes associated request_summaries on destroy" do
    resource = FactoryGirl.create(factory)
    expect(AlaveteliPro::RequestSummary.where(:summarisable_id => resource.id,
                                              :summarisable_type => class_name)).
      to exist
    resource.destroy
    expect(AlaveteliPro::RequestSummary.where(:summarisable_id => resource.id,
                                              :summarisable_type => class_name)).
      not_to exist
  end
end
