module Alaveteli
  module TimeHelpers
    include ActiveSupport::Testing::TimeHelpers

    def time_travel_to(time)
      travel_to(time)
      return unless block_given?
      begin
        travel_to(time)
        yield
      ensure
        travel_back
      end
    end
  end
end
