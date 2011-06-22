# This is a test of the external_command library

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
script_dir = File.join(File.dirname(__FILE__), 'external_command_scripts')
output_script = File.join(script_dir, "output.sh")

require 'external_command'

describe "when running ExternalCommand" do

    it "should get correct status code for /bin/true" do
        t = ExternalCommand.new("/bin/true").run()
        t.status.should == 0
        t.out.should == ""
        t.err.should == ""
    end

    it "should get correct status code for /bin/false" do
        f = ExternalCommand.new("/bin/false").run()
        f.status.should == 1
        f.out.should == ""
        f.err.should == ""
    end

    it "should get stdout and stderr" do
        f = ExternalCommand.new(output_script, "out", "err", "10", "23").run()
        f.status.should == 23
        f.out.should == (0..9).map {|i| "out #{i}\n"}.join("")
        f.err.should == (0..9).map {|i| "err #{i}\n"}.join("")
    end

    it "should work with large amounts of data" do
        f = ExternalCommand.new(output_script, "a longer output line", "a longer error line", "10000", "5").run()
        f.status.should == 5
        f.out.should == (0..9999).map {|i| "a longer output line #{i}\n"}.join("")
        f.err.should == (0..9999).map {|i| "a longer error line #{i}\n"}.join("")
    end

end

