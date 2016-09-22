require 'spec_helper'

describe AlaveteliPro::Account do
  it { should have_one(:user).class_name(AlaveteliPro.user_class) }
end