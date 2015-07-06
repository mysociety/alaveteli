# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminHelper do

    include AdminHelper

    describe :comment_visibility do

        it 'shows the status of a visible comment' do
            comment = Factory.build(:visible_comment)
            comment_visibility(comment).should == 'Visible'
        end

        it 'shows the status of a hidden comment' do
            comment = Factory.build(:hidden_comment)
            comment_visibility(comment).should == 'Hidden'
        end

    end
    
end
