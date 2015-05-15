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
#  last_edit_editor  :string(255)      not null
#  last_edit_comment :text             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  regexp            :boolean
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CensorRule do

    describe :apply_to_text do

        it 'applies the rule to the text' do
            rule = FactoryGirl.build(:censor_rule, :text => 'secret')
            text = 'Some secret text'
            expect(rule.apply_to_text(text)).to eq('Some [REDACTED] text')
        end

        it 'does not mutate the input' do
            rule = FactoryGirl.build(:censor_rule, :text => 'secret')
            text = 'Some secret text'
            rule.apply_to_text(text)
            expect(text).to eq('Some secret text')
        end

        it 'returns the text if the rule is unmatched' do
            rule = FactoryGirl.build(:censor_rule, :text => 'secret')
            text = 'Some text'
            expect(rule.apply_to_text(text)).to eq('Some text')
        end
    end

    describe :apply_to_text! do

        it 'mutates the input' do
            rule = FactoryGirl.build(:censor_rule, :text => 'secret')
            text = 'Some secret text'
            rule.apply_to_text!(text)
            expect(text).to eq('Some [REDACTED] text')
        end

    end
end

describe CensorRule, "substituting things" do

    describe 'when using a text rule' do

        before do
            @censor_rule = CensorRule.new
            @censor_rule.text = "goodbye"
            @censor_rule.replacement = "hello"
        end

        it 'should do basic text substitution' do
            body = "I don't know why you say goodbye"
            @censor_rule.apply_to_text!(body)
            body.should == "I don't know why you say hello"
        end

        it 'should keep size same for binary substitution' do
            body = "I don't know why you say goodbye"
            orig_body = body.dup
            @censor_rule.apply_to_binary!(body)
            body.size.should == orig_body.size
            body.should == "I don't know why you say xxxxxxx"
            body.should_not == orig_body # be sure duplicated as expected
        end

    end

    describe "when using a regular expression rule" do

        before do
            @censor_rule = CensorRule.new(:last_edit_editor => 1,
                                          :last_edit_comment => 'comment')
            @censor_rule.text = "--PRIVATE.*--PRIVATE"
            @censor_rule.replacement = "--REMOVED\nHidden private info\n--REMOVED"
            @censor_rule.regexp = true
            @body =
<<BODY
Some public information
--PRIVATE
Some private information
--PRIVATE
BODY
        end

        it "replaces the regexp with the replacement text when applied to text" do
            @censor_rule.apply_to_text!(@body)
            @body.should ==
<<BODY
Some public information
--REMOVED
Hidden private info
--REMOVED
BODY
        end

        it "replaces the regexp with the same number of 'x' characters as the text replaced
            when applied to binary" do
            @censor_rule.apply_to_binary!(@body)
            @body.should ==
<<BODY
Some public information
xxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxx
BODY
        end

    end

end

describe 'when validating rules' do

    it 'must have the text to redact' do
        censor_rule = CensorRule.new
        expect(censor_rule).to have(1).error_on(:text)
        expect(censor_rule.errors[:text]).to eql(["can't be blank"])
    end

    it 'must have a replacement' do
      expect(CensorRule.new).to have(1).error_on(:replacement)
    end

    it 'must have a last_edit_editor' do
      expect(CensorRule.new).to have(1).error_on(:last_edit_editor)
    end

    it 'must have a last_edit_comment' do
      expect(CensorRule.new).to have(1).error_on(:last_edit_comment)
    end

    describe 'when validating a regexp rule' do

        before do
            @censor_rule = CensorRule.new(:regexp => true,
                                          :text => '*',
                                          :replacement => '---',
                                          :last_edit_comment => 'test',
                                          :last_edit_editor => 'rspec')
        end

        it 'should try to create a regexp from the text' do
            Regexp.should_receive(:new).with('*', Regexp::MULTILINE)
            @censor_rule.valid?
        end

        describe 'if a regexp error is produced' do

            it 'should add an error message to the text field with the regexp error message' do
                Regexp.stub!(:new).and_raise(RegexpError.new("very bad regexp"))
                @censor_rule.valid?.should == false
                @censor_rule.errors[:text].should == ["very bad regexp"]
            end

        end

        describe 'if no regexp error is produced' do

            it 'should not add any error message to the text field' do
                Regexp.stub!(:new)
                @censor_rule.valid?
                @censor_rule.errors[:text].should == []
            end

        end

    end

    describe 'when the allow_global flag has been set' do

        before do
            @censor_rule = CensorRule.new(:text => 'some text',
                                          :replacement => '---',
                                          :last_edit_comment => 'test',
                                          :last_edit_editor => 'rspec')
            @censor_rule.allow_global = true
        end

        it 'should allow a global censor rule (without user_id, request_id or public_body_id)' do
            @censor_rule.valid?.should == true
        end

    end

    describe 'when the allow_global flag has not been set' do

        before do
            @censor_rule = CensorRule.new(:text => '/./',
                                          :replacement => '---',
                                          :last_edit_comment => 'test',
                                          :last_edit_editor => 'rspec')
        end

        it 'should not allow a global text censor rule (without user_id, request_id or public_body_id)' do
            @censor_rule.valid?.should == false

            expected_error = ["Rule must apply to an info request, a user or a body"]
            @censor_rule.errors[:user].should == expected_error
            @censor_rule.errors[:info_request].should == expected_error
            @censor_rule.errors[:public_body].should == expected_error
        end

        it 'should not allow a global regex censor rule (without user_id, request_id or public_body_id)' do
            @censor_rule.regexp = true
            @censor_rule.valid?.should == false

            expected_error = ["Rule must apply to an info request, a user or a body"]
            @censor_rule.errors[:user].should == expected_error
            @censor_rule.errors[:info_request].should == expected_error
            @censor_rule.errors[:public_body].should == expected_error
        end

    end

end

describe 'when handling global rules' do

    describe 'an instance without user_id, request_id or public_body_id' do

        before do
            @global_rule = CensorRule.new
        end

        it 'should return a value of true from is_global?' do
           @global_rule.is_global?.should == true
        end

    end

    describe 'the scope CensorRule.global.all' do

        before do
            @global_rule = CensorRule.create!(:allow_global => true,
                                              :text => 'hide me',
                                              :replacement => 'nothing to see here',
                                              :last_edit_editor => 1,
                                              :last_edit_comment => 'comment')
            @user_rule = CensorRule.create!(:user_id => 1,
                                            :text => 'hide me',
                                            :replacement => 'nothing to see here',
                                            :last_edit_editor => 1,
                                            :last_edit_comment => 'comment')
        end

        it 'should include an instance without user_id, request_id or public_body_id' do
            CensorRule.global.all.include?(@global_rule).should == true
        end

        it 'should not include a request with user_id' do
            CensorRule.global.all.include?(@user_rule).should == false
        end

        after do
            @global_rule.destroy if @global_rule
            @user_rule.destroy if @user_rule
        end
    end

end


