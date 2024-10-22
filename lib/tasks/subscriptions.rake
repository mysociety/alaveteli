namespace :subscriptions do
  desc 'Migrate Stripe subscription to new price'
  task migrate_price: :environment do
    old_price, new_price = *load_prices

    scope = Stripe::Subscription.list(price: old_price.id)
    count = scope.data.size

    scope.auto_paging_each.with_index do |subscription, index|
      item = subscription.items.first
      Stripe::Subscription.update(
        subscription.id,
        items: [{ id: item.id, price: new_price.id }],
        proration_behavior: 'none'
      )

      erase_line
      print "Migrated subscriptions #{index + 1}/#{count}"
    end

    erase_line
    puts "Migrating all subscriptions completed."
  end

  def load_prices
    old_price = AlaveteliPro::Price.retrieve(ENV['OLD_PRICE']) if ENV['OLD_PRICE']
    new_price = AlaveteliPro::Price.retrieve(ENV['NEW_PRICE']) if ENV['NEW_PRICE']

    if !old_price
      puts "ERROR: Can't find OLD_PRICE"
      exit 1
    elsif !new_price
      puts "ERROR: Can't find NEW_PRICE"
      exit 1
    elsif old_price.recurring != new_price.recurring
      puts "ERROR: Price interval and interval_count need to match"
      exit 1
    end

    [old_price, new_price]
  end

  def erase_line
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences
    print "\e[1G\e[K"
  end
end
