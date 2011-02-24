require 'spec/spec_helper'

de_file = File.join('spec','locale','de','LC_MESSAGES','test.mo')
de = FastGettext::MoFile.new(de_file)

describe FastGettext::MoFile do
  before :all do
    File.exist?(de_file).should == true
  end

  it "parses a file" do
    de['car'].should == 'Auto'
  end

  it "stores untranslated values as nil" do
    de['Car|Model'].should == nil
  end

  it "finds pluralized values" do
    de.plural('Axis','Axis').should == ['Achse','Achsen']
  end

  it "returns singular translations when pluralisation could not be found" do
    de.plural('Axis','Axis','Axis').should == ['Achse','Achse','Achse']
  end

  it "returns ids when not plural and singular translations could not be found" do
    de.plural('Axis','Axis','NOTFOUND').should == ['Achse','Achse','NOTFOUND']
  end

  it "can access plurals through []" do
    de['Axis'].should == 'Achse' #singular
  end
end