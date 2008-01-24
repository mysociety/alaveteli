require File.dirname(__FILE__) + '/../spec_helper'

describe PublicBody, " when saving" do
    before do
        @public_body = PublicBody.new 
    end

    it "should not save without setting some parameters" do
        lambda { @public_body.save! }.should raise_error(ActiveRecord::RecordInvalid)
    end

    it "should not save with misformatted request email" do
        @public_body.name = "Testing Public Body"
        @public_body.short_name = "TPB"
        @public_body.request_email = "requestBOOlocalhost"
        @public_body.complaint_email = "complaint@localhost"
        @public_body.last_edit_editor = "*test*"
        @public_body.last_edit_comment = "This is a test"
        lambda { @public_body.save! }.should raise_error(ActiveRecord::RecordInvalid)
    end

    it "should not save with misformatted complaint email" do
        @public_body.name = "Testing Public Body"
        @public_body.short_name = "TPB"
        @public_body.request_email = "request@localhost"
        @public_body.complaint_email = "complaintBOOlocalhost"
        @public_body.last_edit_editor = "*test*"
        @public_body.last_edit_comment = "This is a test"
        lambda { @public_body.save! }.should raise_error(ActiveRecord::RecordInvalid)
    end

    it "should save" do
        @public_body.name = "Testing Public Body"
        @public_body.short_name = "TPB"
        @public_body.request_email = "request@localhost"
        @public_body.complaint_email = "complaint@localhost"
        @public_body.last_edit_editor = "*test*"
        @public_body.last_edit_comment = "This is a test"
        @public_body.save!
    end
end



