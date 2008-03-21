require File.dirname(__FILE__) + '/../spec_helper'

describe InfoRequestEvent, " when " do

    it "should convert event parameters into YAML and back successfully" do
        ire = InfoRequestEvent.new 
        example_params = { :foo => 'this is stuff', :bar => 83, :humbug => "yikes!!!" }
        ire.params = example_params
        ire.params_yaml.should == example_params.to_yaml
        ire.params.should == example_params
    end

end

