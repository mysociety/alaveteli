# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: post_redirects
#
#  id                 :integer          not null, primary key
#  token              :text             not null
#  uri                :text             not null
#  post_params_yaml   :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  email_token        :text             not null
#  reason_params_yaml :text
#  user_id            :integer
#  circumstance       :text             default("normal"), not null
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PostRedirect, " when constructing" do
  before do
  end

  it "should generate a different token from email token" do
    pr = PostRedirect.new
    expect(pr.token).not_to eq(pr.email_token)
  end

  it "should generate a different token each time" do
    pr_1 = PostRedirect.new
    pr_2 = PostRedirect.new
    expect(pr_1.token).not_to be_nil
    expect(pr_2.token).not_to be_nil
    expect(pr_1.token).not_to eq(pr_2.token)
  end

  it "should generate a different email each time" do
    pr_1 = PostRedirect.new
    pr_2 = PostRedirect.new
    expect(pr_1.email_token).not_to be_nil
    expect(pr_2.email_token).not_to be_nil
    expect(pr_1.email_token).not_to eq(pr_2.email_token)
  end

  it "should generate a URL friendly token" do
    pr = PostRedirect.new
    expect(pr.token).to match(/[a-z0-9]+/);
  end

  it "should generate an email friendly email token" do
    pr = PostRedirect.new
    expect(pr.email_token).to match(/[a-z0-9]+/);
  end
end

describe PostRedirect, " when accessing values" do
  before do
  end

  it "should convert post parameters into YAML and back successfully" do
    pr = PostRedirect.new
    example_post_params = { :foo => 'this is stuff', :bar => 83, :humbug => "yikes!!!" }
    pr.post_params = example_post_params
    expect(pr.post_params_yaml).to eq(example_post_params.to_yaml)
    expect(pr.post_params).to eq(example_post_params)
  end

  it "should convert reason parameters into YAML and back successfully" do
    pr = PostRedirect.new
    example_reason_params = { :foo => 'this is stuff', :bar => 83, :humbug => "yikes!!!" }
    pr.reason_params = example_reason_params
    expect(pr.reason_params_yaml).to eq(example_reason_params.to_yaml)
    expect(pr.reason_params).to eq(example_reason_params)
  end

  it "should restore UTF8-heavy params stored under ruby 1.8 as UTF-8" do
    pr = PostRedirect.new
    utf8_params = "--- \n:foo: !binary |\n  0KLQvtCz0LDRiCDR\n"
    pr.reason_params_yaml = utf8_params
    expect(pr.reason_params[:foo].encoding.to_s).to eq('UTF-8') if pr.reason_params[:foo].respond_to?(:encoding)
  end
end
