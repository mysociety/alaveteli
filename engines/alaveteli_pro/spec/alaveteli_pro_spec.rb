require 'spec_helper'

describe AlaveteliPro do
  it "allows you to set the user class" do
    AlaveteliPro.user_class = "User"
    expect(AlaveteliPro.user_class).to eq "User"
  end

  it "allows you to set the site name" do
    AlaveteliPro.site_name = "Alaveteli"
    expect(AlaveteliPro.site_name).to eq "Alaveteli"
  end
end
