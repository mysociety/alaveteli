# -*- encoding : utf-8 -*-
#
# Public: Class to check whether the current database supports collation for
# a given language. Prefer the class method .supports? rather than creating a
# new instance.
class DatabaseCollation
  MINIMUM_POSTGRESQL_VERSION = 90112

  attr_reader :connection

  # Public: Does the connected database support collation in the given locale?
  # Delegates to an instance configured with a connection from the
  # ActiveRecord::Base connection pool. See DatabaseCollation#supports? for
  # more documentation.
  def self.supports?(locale)
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      i = new(connection)
      i.supports?(locale)
    end
  end

  def initialize(connection)
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
    sql = <<-EOF.strip_heredoc.squish
    SELECT collname FROM pg_collation
    WHERE collencoding = '-1'
    OR collencoding = '#{ database_encoding }';
    EOF

    @supported_collations ||=
      connection.execute(sql).map { |row| row['collname'] }
  end

  def database_encoding
    sql = <<-EOF.strip_heredoc.squish
    SELECT encoding FROM pg_database
    WHERE datname = '#{ connection.current_database }';
    EOF

    @database_encoding ||= connection.execute(sql).first["encoding"]
  end

  def adapter_name
    @adapter_name ||= connection.adapter_name
  end
end
