RSpec.shared_examples 'user/spreadable_alerts' do
  describe '.random_time_in_last_day' do
    # TODO
  end

  describe '.spread_alert_times_across_day' do
    # TODO
  end

  describe '#daily_summary_time' do
    let(:user) do
      FactoryBot.create(:user, daily_summary_hour: 7,
                               daily_summary_minute: 56)
    end

    it "returns the hour and minute of the user's daily summary time" do
      expected_hash = { hour: 7, min: 56 }
      expect(user.daily_summary_time).to eq(expected_hash)
    end
  end

  describe "setting daily_summary_time on new users" do
    let(:user) { FactoryBot.create(:user) }
    let(:expected_time) { Time.zone.now.change(hour: 7, min: 57) }

    before do
      allow(User).
        to receive(:random_time_in_last_day).and_return(expected_time)
    end

    it "sets a random hour and minute on initialization" do
      expect(user.daily_summary_hour).to eq(7)
      expect(user.daily_summary_minute).to eq(57)
    end

    it "doesn't override the hour and minute if they're already set" do
      user = FactoryBot.create(:user, daily_summary_hour: 9,
                                      daily_summary_minute: 15)
      expect(user.daily_summary_hour).to eq(9)
      expect(user.daily_summary_minute).to eq(15)
    end

    it "doesn't change the the hour and minute once they're set" do
      user.save!
      expect(user.daily_summary_hour).to eq(7)
      expect(user.daily_summary_minute).to eq(57)
    end
  end
end
