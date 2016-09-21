require 'spec_helper'

describe AlaveteliPro do
  it "allows you to set the user class" do
    AlaveteliPro.user_class = "User"
    expect(AlaveteliPro.user_class).to eq "User"
  end
end
