# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: censor_rules
#
#  id                :integer          not null, primary key
#  info_request_id   :integer
#  user_id           :integer
#  public_body_id    :integer
#  text              :text             not null
#  replacement       :text             not null
#  last_edit_editor  :string           not null
#  last_edit_comment :text             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  regexp            :boolean
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CensorRule do

  describe '#apply_to_text' do

    it 'applies the rule to the text' do
      rule = FactoryBot.build(:censor_rule, text: 'secret')
      text = 'Some secret text'
      expect(rule.apply_to_text(text)).to eq('Some [REDACTED] text')
    end

    it 'does not mutate the input' do
      rule = FactoryBot.build(:censor_rule, text: 'secret')
      text = 'Some secret text'
      rule.apply_to_text(text)
      expect(text).to eq('Some secret text')
    end

    it 'returns the text if the rule is unmatched' do
      rule = FactoryBot.build(:censor_rule, text: 'secret')
      text = 'Some text'
      expect(rule.apply_to_text(text)).to eq('Some text')
    end

    it 'replaces the regexp with the replacement text when applied to text' do
      attrs = { text: '--PRIVATE.*--PRIVATE',
                replacement: "--REMOVED\nHidden private info\n--REMOVED",
                regexp: true }
      rule = FactoryBot.build(:censor_rule, attrs)
      text = <<-EOF.strip_heredoc
      Some public information
      --PRIVATE
      Some private information
      --PRIVATE
      EOF

      expect(rule.apply_to_text(text)).to eq <<-EOF.strip_heredoc
      Some public information
      --REMOVED
      Hidden private info
      --REMOVED
      EOF
    end

  end

  describe '#apply_to_binary' do

    it 'applies the rule to the text' do
      rule = FactoryBot.build(:censor_rule, text: 'secret')
      text = 'Some secret text'
      expect(rule.apply_to_binary(text)).to eq('Some xxxxxx text')
    end

    it 'does not modify the size of the string' do
      rule = FactoryBot.build(:censor_rule, text: 'secret')
      text = 'Some secret text'
      original_text = text.dup
      redacted = rule.apply_to_binary(text)
      expect(redacted.size).to eq(original_text.size)
    end

    it 'does not mutate the input' do
      rule = FactoryBot.build(:censor_rule, text: 'secret')
      text = 'Some secret text'
      rule.apply_to_binary(text)
      expect(text).to eq('Some secret text')
    end

    it 'returns the text if the rule is unmatched' do
      rule = FactoryBot.build(:censor_rule, text: 'secret')
      text = 'Some text'
      expect(rule.apply_to_binary(text)).to eq('Some text')
    end

    it 'handles a UTF-8 rule and ASCII-8BIT text' do
      rule = FactoryBot.build(:censor_rule, text: 'sécret')
      text = 'Some sécret text'
      text.force_encoding('ASCII-8BIT') if String.method_defined?(:encode)
      expect(rule.apply_to_binary(text)).to eq("Some xxxxxxx text")
    end

    it "replaces the regexp with the same number of 'x' characters as the text
        replaced when applied to binary" do
      attrs = { text: '--PRIVATE.*--PRIVATE',
                replacement: "--REMOVED\nHidden private info\n--REMOVED",
                regexp: true }
      rule = FactoryBot.build(:censor_rule, attrs)
      text = <<-EOF.strip_heredoc
      Some public information
      --PRIVATE
      Some private information
      --PRIVATE
      EOF

      expect(rule.apply_to_binary(text)).to eq <<-EOF.strip_heredoc
      Some public information
      xxxxxxxxx
      xxxxxxxxxxxxxxxxxxxxxxxx
      xxxxxxxxx
      EOF
    end

    it 'handles a UTF-8 rule with ASCII-8BIT text' do
      attrs = { text: '--PRIVATE.*--P‘RIVATE',
                replacement: "--REMOVED\nHidden private info\n--REMOVED",
                regexp: true }
      rule = FactoryBot.build(:censor_rule, attrs)
      text = <<-EOF.strip_heredoc
      Some public information
      --PRIVATE
      Some private information
      --P‘RIVATE
      EOF
      text.force_encoding('ASCII-8BIT') if String.method_defined?(:encode)

      expect(rule.apply_to_binary(text)).to eq <<-EOF.strip_heredoc
      Some public information
      xxxxxxxxx
      xxxxxxxxxxxxxxxxxxxxxxxx
      xxxxxxxxxxxx
      EOF
    end

  end

  describe '#expire_requests' do

    it 'calls expire on the request if it is a request rule' do
      request = FactoryBot.create(:info_request)
      rule = FactoryBot.create(:info_request_censor_rule,
                               info_request: request)
      expect(request).to receive(:expire)
      rule.expire_requests
    end

    it 'calls expire_requests on the user if it is a user rule' do
      user = FactoryBot.create(:user)
      rule = FactoryBot.create(:user_censor_rule, user: user)
      expect(user).to receive(:expire_requests)
      rule.expire_requests
    end

    it 'calls expire_requests on the public body if it is a public body rule' do
      body = FactoryBot.create(:public_body)
      rule = FactoryBot.create(:public_body_censor_rule, public_body: body)
      expect(body).to receive(:expire_requests)
      rule.expire_requests
    end

    it 'calls expire on all public requests if it is a global rule' do
      rule = FactoryBot.build(:global_censor_rule)
      requests = [double, double]
      expect(InfoRequest).to receive(:find_in_batches).and_yield(requests)

      requests.each do |request|
        expect(request).to receive(:expire)
      end

      rule.expire_requests
    end

  end

end

describe 'when validating rules' do

  it 'must have the text to redact' do
    censor_rule = CensorRule.new
    censor_rule.valid?
    expect(censor_rule.errors[:text].size).to eq(1)
    expect(censor_rule.errors[:text]).to eql(["can't be blank"])
  end

  it 'must have a replacement' do
    censor_rule = CensorRule.new
    censor_rule.valid?
    expect(censor_rule.errors[:replacement].size).to eq(1)
  end

  it 'must have a last_edit_editor' do
    censor_rule = CensorRule.new
    censor_rule.valid?
    expect(censor_rule.errors[:last_edit_editor].size).to eq(1)
  end

  it 'must have a last_edit_comment' do
    censor_rule = CensorRule.new
    censor_rule.valid?
    expect(censor_rule.errors[:last_edit_comment].size).to eq(1)
  end

  describe 'when validating a regexp rule' do

    before do
      @censor_rule = CensorRule.new(regexp: true,
                                    text: '*',
                                    replacement: '---',
                                    last_edit_comment: 'test',
                                    last_edit_editor: 'rspec')
    end

    it 'should try to create a regexp from the text' do
      expect(Regexp).to receive(:new).with('*', Regexp::MULTILINE)
      @censor_rule.valid?
    end

    describe 'if a regexp error is produced' do

      it 'should add an error message to the text field with the regexp error message' do
        allow(Regexp).to receive(:new).and_raise(RegexpError.new("very bad regexp"))
        expect(@censor_rule.valid?).to eq(false)
        expect(@censor_rule.errors[:text]).to eq(["very bad regexp"])
      end

    end

    describe 'if no regexp error is produced' do

      it 'should not add any error message to the text field' do
        allow(Regexp).to receive(:new)
        @censor_rule.valid?
        expect(@censor_rule.errors[:text]).to eq([])
      end

    end

  end

end

describe 'when handling global rules' do

  describe 'an instance without user_id, request_id or public_body_id' do

    before do
      @global_rule = CensorRule.new
    end

    it 'should return a value of true from is_global?' do
      expect(@global_rule.is_global?).to eq(true)
    end

  end

  describe '.global' do

    before do
      @global_rule = CensorRule.create!(text: 'hide me',
                                        replacement: 'nothing to see here',
                                        last_edit_editor: 1,
                                        last_edit_comment: 'comment')
      @user_rule = CensorRule.create!(user_id: 1,
                                      text: 'hide me',
                                      replacement: 'nothing to see here',
                                      last_edit_editor: 1,
                                      last_edit_comment: 'comment')
    end

    it 'should include an instance without user_id, request_id or public_body_id' do
      expect(CensorRule.global.include?(@global_rule)).to eq(true)
    end

    it 'should not include a request with user_id' do
      expect(CensorRule.global.include?(@user_rule)).to eq(false)
    end

    after do
      @global_rule.destroy if @global_rule
      @user_rule.destroy if @user_rule
    end
  end

end
