require 'spec_helper'

describe AlaveteliPro::Account do
  it { should belong_to(:user).class_name(AlaveteliPro.user_class) }
end