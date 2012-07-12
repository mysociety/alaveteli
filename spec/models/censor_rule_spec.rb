require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CensorRule, "substituting things" do 
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

    context "when regexp type" do
        before do
            CensorRule.delete_all
            CensorRule.create(:last_edit_editor => 1,
                              :last_edit_comment => 'comment')
            @censor_rule = CensorRule.new(:last_edit_editor => 1,
                                          :last_edit_comment => 'comment')
            @censor_rule.text = "--PRIVATE.*--PRIVATE"
            @censor_rule.replacement = "--REMOVED\nHidden private info\n--REMOVED"
            @censor_rule.regexp = true
        end

        it "replaces with the regexp" do
            body =
<<BODY
Some public information
--PRIVATE
Some private information
--PRIVATE
BODY
            @censor_rule.apply_to_text!(body)
            body.should ==
<<BODY
Some public information
--REMOVED
Hidden private info
--REMOVED
BODY
        end

        it "validates without info_request, user or public body set" do
          @censor_rule.save.should be_true
        end

        it "has scope for regexps" do
          @censor_rule.save
          CensorRule.regexps.all.should == [@censor_rule]
        end
    end
end

