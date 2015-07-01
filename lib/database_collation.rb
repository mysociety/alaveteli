# -*- encoding : utf-8 -*-
#
# Public: Class to check whether the current database supports collation for
# a given language. Prefer the class method .supports? rather than creating a
# new instance.
class DatabaseCollation
  DEFAULT_CONNECTION = ActiveRecord::Base.connection
  MINIMUM_POSTGRESQL_VERSION = 90112

  attr_reader :connection

  # Public: Does the connected database support collation in the given locale?
  # Delegates to an instance configured with the DEFAULT_CONNECTION. See
  # DatabaseCollation#supports? for more documentation.
  def self.supports?(locale)
    instance.supports?(locale)
  end

  def self.instance
    @instance ||= new
  end

  def initialize(connection = DEFAULT_CONNECTION)
    @connection = connection
  end

  # Public: Does the connected database support collation in the given locale?
  #
  # locale - String locale name
  #
  # Examples
  #
  #   database.supports? 'en_GB'
  #   # => true
  #   database.supports? 'es'
  #   # => false
  #
  # Returns a Boolean
  def supports?(locale)
    exist? && supported_collations.include?(locale)
  end

  private

  def exist?
    postgresql? && postgresql_version >= MINIMUM_POSTGRESQL_VERSION
  end

  def postgresql?
    adapter_name == 'PostgreSQL'
  end

  def postgresql_version
    @postgresql_version ||= connection.send(:postgresql_version) if postgresql?
  end

  def supported_collations
    @supported_collations ||= connection.
      execute(%q(SELECT collname FROM pg_collation;)).
        map { |row| row['collname'] }
  end

  def adapter_name
    @adapter_name ||= connection.adapter_name
  end
end
