# -*- encoding : utf-8 -*-
class DropUnconventionalPublicBodyConstraints < ActiveRecord::Migration[4.2] # 4.1
  DATA = { PublicBody => [:short_name,
                          :home_page,
                          :notes,
                          :publication_scheme,
                          :disclosure_log,
                          :last_edit_comment],
           PublicBody::Version => [:publication_scheme,
                                   :disclosure_log,
                                   :charity_number] }.freeze

  TRANSLATED_DATA = { PublicBody::Translation => [:name,
                                                  :short_name,
                                                  :notes,
                                                  :publication_scheme,
                                                  :disclosure_log] }.freeze
  def up
    DATA.each do |klass, columns|
      table = klass.table_name

      columns.each do |column|
        # Allow NULL values
        change_column_null table, column, true

        # Remove the default("") value
        change_column_default table, column, nil

        # Where an old default("") value has been set, replace it with NULL
        klass.where(column => '').update_all(column => nil)
      end
    end

    # The translation table doesn't have any constraints, but we want to update
    # the data to be consistent with the parent data.
    TRANSLATED_DATA.each do |klass, columns|
      columns.each do |column|
        klass.where(column => '').update_all(column => nil)
      end
    end
  end

  def down
    DATA.each do |klass, columns|
      table = klass.table_name

      columns.each do |column|
        # Disallow NULL values, setting the replacement as ''
        change_column_null table, column, false, ''

        # Add a default("") value
        change_column_default table, column, ''
      end
    end

    # The translation table doesn't have any constraints, but we want to update
    # the data to be consistent with the parent data.
    TRANSLATED_DATA.each do |klass, columns|
      columns.each do |column|
        klass.where(column => nil).update_all(column => '')
      end
    end
  end
end
