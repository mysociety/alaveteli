namespace :temp do
  desc 'Populate User#status_update_count'
  task populate_user_status_update_count: :environment do
    scope = User.all
    count = scope.count

    scope.find_each.with_index do |user, index|
      update_count = InfoRequestEvent.
        where(event_type: 'status_update').
        where("params -> 'user' ->> 'gid' = ?", user.to_gid.to_s).
        count

      user.update_columns(status_update_count: update_count)

      erase_line
      print "Populating User#status_update_count #{index + 1}/#{count}"
    end

    erase_line
    puts "Populating User#status_update_count completed."
  end

  desc 'Migrate PublicBodyCategory into Category model'
  task migrate_public_body_categories: :environment do
    next if PublicBody.categories.any?

    scope = PublicBodyCategoryLink.by_display_order.to_a
    count = scope.count

    root = PublicBody.category_root

    scope.each.with_index do |link, index|
      h = link.public_body_heading
      heading = Category.with_parent(root).find_by(title: h.name)
      heading ||= Category.create!(
        translations_attributes: h.translations_by_locale do
          { locale: _1.locale, title: _1.name }
        end
      )
      heading.parents << root unless heading.parents.include?(root)

      c = link.public_body_category
      category = Category.find_by(title: c.title, category_tag: c.category_tag)
      category ||= Category.create!(
        category_tag: c.category_tag,
        translations_attributes: c.translations_by_locale do
          { locale: _1.locale, title: _1.title, description: _1.description }
        end
      )
      category.parents << heading unless category.parents.include?(heading)

      erase_line
      print "Migrate PublicBodyCategory to Category #{index + 1}/#{count}"
    end

    erase_line
    puts "Migrating to PublicBodyCategory completed."
  end

  desc 'Migrate PublicBody#disclosure_log to translation model'
  task migrate_disclosure_log: :environment do
    class PublicBodyWithoutTranslations < ApplicationRecord # :nodoc:
      self.table_name = 'public_bodies'

      def with_translation
        AlaveteliLocalization.with_default_locale { PublicBody.find(id) }
      end
    end

    scope = PublicBodyWithoutTranslations.where.not(disclosure_log: nil)
    count = scope.count

    scope.find_each.with_index do |pb, index|
      pb.with_translation.update(disclosure_log: pb.disclosure_log)

      erase_line
      print "Migrate PublicBody#disclosure_log to " \
        "PublicBody::Translation#disclosure_log #{index + 1}/#{count}"
    end

    erase_line
    puts "Migrating to PublicBody::Translation#disclosure_log completed."
  end

  desc 'Migrate current User#url_name to new slug model'
  task migrate_user_slugs: :environment do
    scope = User.left_joins(:slugs).where(slugs: { id: nil })
    count = scope.count

    scope.find_each.with_index do |user, index|
      user.slugs.create!(slug: user.url_name)

      erase_line
      print "Migrate User#url_name to User#slugs #{index + 1}/#{count}"
    end

    erase_line
    puts "Migrating to User#slugs completed."
  end

  desc 'Populate OutgoingMessage#from_name'
  task populate_outgoing_message_from_name: :environment do
    scope = OutgoingMessage.where(from_name: nil).includes(:user)
    count = scope.count

    scope.find_each.with_index do |outgoing_message, index|
      user = outgoing_message.user
      name = user.read_attribute(:name)
      outgoing_message.update_columns(from_name: name)

      erase_line
      print "Populating OutgoingMessage#from_name #{index + 1}/#{count}"
    end

    erase_line
    puts "Populating OutgoingMessage#from_name completed."
  end

  def erase_line
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences
    print "\e[1G\e[K"
  end
end
