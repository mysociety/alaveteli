# -*- encoding : utf-8 -*-
class User
  class TransactionCalculator
    DEFAULT_TRANSACTION_ASSOCIATIONS = [
      :comments,
      :info_requests,
      :public_body_change_requests,
      :request_classifications,
      :track_things
    ]

    attr_reader :transaction_associations
    attr_reader :user

    def initialize(user, options = {})
      @user = user
      @transaction_associations =
        options.
          fetch(:transaction_associations) { DEFAULT_TRANSACTION_ASSOCIATIONS }

      transaction_associations.each do |assoc|
        unless user.respond_to?(assoc)
          raise NoMethodError, "#{ user } does not respond to `#{ assoc }'"
        end
      end
    end

    # Public: Sum of the total transactions made by the User
    #
    # filter - Optionally filter by created_at during the Symbol named range or
    #          Range (default: :current)
    #
    # Returns an Integer
    # Raises ArgumentError if the argument is an invalid named range or
    # or otherwise invalid
    def total(filter = :current)
      case filter
      when :current
        transaction_associations.
          reduce(0) { |accum, assoc| accum += user.send(assoc).count }
      when Symbol
        range_total_count(named_range(filter))
      when Range
        range_total_count(filter)
      else
        raise ArgumentError, "Invalid argument `#{ filter }'"
      end
    end

    # Public: Hash of total transactions grouped by month.
    # Months with no transactions are not included
    #
    # Returns a Hash
    def total_per_month
      results = transaction_associations.reduce({}) do |memo, assoc|
        # Get the grouped counts for the association
        assoc_results =
          user.
            send(assoc).
              group("DATE_TRUNC('month', created_at)").
                reorder("date_trunc_month_created_at").
                  count

        # Add the counts to existing keys, or set new keys if they don't exist
        assoc_results.each do |key, value|
          memo[key] ||= 0
          memo[key] += value
        end

        memo
      end

      # Convert DateTime keys to String keys
      results.reduce({}) do |memo, pair|
        memo[pair.first.to_date.to_s] = pair.last
        memo
      end
    end

    private

    def range_total_count(range)
      transaction_associations.
        reduce(0) do |accum, assoc|
          accum += user.send(assoc).where(:created_at => range).count
        end
    end

    def named_range(symbol)
      case symbol
      when :last_7_days
        7.days.ago.beginning_of_day..Time.zone.now.end_of_day
      when :last_30_days
        30.days.ago.beginning_of_day..Time.zone.now.end_of_day
      when :last_30_days
        30.days.ago.beginning_of_day..Time.zone.now.end_of_day
      when :last_quarter
        end_of_last = Time.zone.now.beginning_of_quarter - 1.day
        qstart = end_of_last.beginning_of_quarter
        qend = end_of_last.end_of_quarter
        qstart..qend
      else
        raise ArgumentError, "Invalid range `:#{ symbol }'"
      end
    end
  end
end
