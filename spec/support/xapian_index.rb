# -*- encoding : utf-8 -*-
# Rebuild the current xapian index
def rebuild_xapian_index(terms = true, values = true, texts = true, dropfirst = true)
  if dropfirst
    begin
      ActsAsXapian.readable_init
      FileUtils.rm_r(ActsAsXapian.db_path)
    rescue RuntimeError
    end
    ActsAsXapian.writable_init
    ActsAsXapian.writable_db.close
  end
  parse_all_incoming_messages
  # safe_rebuild=true, which involves forking to avoid memory leaks, doesn't work well with rspec.
  # unsafe is significantly faster, and we can afford possible memory leaks while testing.
  models = [PublicBody, User, InfoRequestEvent]
  ActsAsXapian.rebuild_index(models, verbose=false, terms, values, texts, safe_rebuild=false)
end

def update_xapian_index
  ActsAsXapian.update_index(flush_to_disk=false, verbose=false)
end

# Copy the xapian index created in create_fixtures_xapian_index to a temporary
# copy at the same level and point xapian at the copy
def get_fixtures_xapian_index
  # Create a base index for the fixtures if not already created
  $existing_xapian_db ||= create_fixtures_xapian_index
  # Store whatever the xapian db path is originally
  $original_xapian_path ||= ActsAsXapian.db_path
  path_array = $original_xapian_path.split(File::Separator)
  path_array.pop
  temp_path = File.join(path_array, 'test.temp')
  FileUtils.remove_entry_secure(temp_path, force=true)
  FileUtils.cp_r($original_xapian_path, temp_path)
  ActsAsXapian.db_path = temp_path
end

# Create a clean xapian index based on the fixture files and the raw_email data.
def create_fixtures_xapian_index
  load_raw_emails_data
  rebuild_xapian_index
end
