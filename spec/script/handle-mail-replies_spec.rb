# -*- encoding : utf-8 -*-
require "spec_helper"
require "external_command"

describe "When filtering" do

  describe "when not in test mode" do

    it "should not fail handling a bounce mail" do
      xc = ExternalCommand.new("script/handle-mail-replies",
                               { :stdin_string => load_file_fixture("track-response-exim-bounce.email") })
      xc.run
      puts xc.out
      expect(xc.err).to eq("")
    end

  end

end
