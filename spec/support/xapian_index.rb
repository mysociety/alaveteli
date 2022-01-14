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
  load_raw_emails_data
  parse_all_incoming_messages
  ActsAsXapian::ActsAsXapianJob.destroy_all
  # safe_rebuild=true, which involves forking to avoid memory leaks, doesn't work well with rspec.
  # unsafe is significantly faster, and we can afford possible memory leaks while testing.
  models = [PublicBody, User, InfoRequestEvent]
  ActsAsXapian.destroy_and_rebuild_index(models, verbose=false, terms, values, texts, safe_rebuild=false)
end

def update_xapian_index
  if $xapian_index_setup.nil?
    $xapian_index_setup = true
    return destroy_and_rebuild_xapian_index
  end

  ActsAsXapian.update_index(flush_to_disk=false, verbose=false)
end
