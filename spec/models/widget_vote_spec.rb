# == Schema Information
#
# Table name: widget_votes
#
#  id              :integer          not null, primary key
#  cookie          :string(255)
#  info_request_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WidgetVote do

    describe :new do

        it 'requires an info request' do
            widget_vote = WidgetVote.new
            widget_vote.should_not be_valid
            widget_vote.errors[:info_request].should == ["can't be blank"]
        end

        it 'validates the cookie length' do
            widget_vote = WidgetVote.new
            widget_vote.should_not be_valid
            widget_vote.errors[:cookie].should == ["is the wrong length (should be 20 characters)"]
        end

        it 'is valid with a cookie and info request' do
            widget_vote = FactoryGirl.create(:info_request).widget_votes.build(:cookie => 'x' * 20)
            widget_vote.should be_valid
        end

    end

end
