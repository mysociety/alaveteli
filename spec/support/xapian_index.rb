# Rebuild the current xapian index
def destroy_and_rebuild_xapian_index(terms = true, values = true, texts = true, dropfirst = true)
  if dropfirst
    begin
      ActsAsXapian.readable_init
      FileUtils.rm_rf(ActsAsXapian.db_path)
    rescue RuntimeError
    end
    ActsAsXapian.writable_init
    ActsAsXapian.writable_db.close
  end
  parse_all_incoming_messages
  # safe_rebuild=true, which involves forking to avoid memory leaks, doesn't work well with rspec.
  # unsafe is significantly faster, and we can afford possible memory leaks while testing.
  models = [PublicBody, User, InfoRequestEvent]
  ActsAsXapian.destroy_and_rebuild_index(models, verbose=false, terms, values, texts, safe_rebuild=false)
end

def update_xapian_index
  get_fixtures_xapian_index unless @xapian_setup
  @xapian_setup = true

  ActsAsXapian.update_index(flush_to_disk=false, verbose=false)
end

# Copy the initial xapian index to a temporary copy at the same level and point
# xapian at the copy
def get_fixtures_xapian_index
  return unless $original_xapian_path

  temp_path = File.join(File.dirname($original_xapian_path), 'test.temp')
  FileUtils.rm_rf(temp_path)

  FileUtils.cp_r($original_xapian_path, temp_path)
  ActsAsXapian.db_path = temp_path
end

# Create a clean xapian index based on the fixture files and the raw_email data.
def create_fixtures_xapian_index
  load_raw_emails_data
  destroy_and_rebuild_xapian_index
end

module ActiveRecord
  class FixtureSet
    class << self
      alias create_fixtures_orig create_fixtures

      def create_fixtures(*args)
        result = create_fixtures_orig(*args)
        $original_xapian_path ||= create_fixtures_xapian_index
        result
      end
    end
  end
end
