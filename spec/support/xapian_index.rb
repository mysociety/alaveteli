# -*- encoding : utf-8 -*-
# Rebuild the current xapian index
def destroy_and_rebuild_xapian_index(terms = true, values = true, texts = true, dropfirst = true)
  if dropfirst
      puts "-->> dropfirst"
    begin
      puts "-->> readable_init"
      ActsAsXapian.readable_init
      puts "-->> rm_rf ActsAsXapian.db_path"
      FileUtils.rm_rf(ActsAsXapian.db_path)
      puts "-->> done"
    rescue RuntimeError
      puts "RuntimeError destroy_and_rebuild_index dropfirst"
    end
      puts "-->> writable_init"
    ActsAsXapian.writable_init
      puts "-->> writable_db.close"
    ActsAsXapian.writable_db.close
  end
  puts "-->> parse_all_incoming_messages"
  parse_all_incoming_messages
  # safe_rebuild=true, which involves forking to avoid memory leaks, doesn't work well with rspec.
  # unsafe is significantly faster, and we can afford possible memory leaks while testing.
  models = [PublicBody, User, InfoRequestEvent]
  puts "-->> destroy_and_rebuild_index"
  return_val = ActsAsXapian.destroy_and_rebuild_index(models, verbose=false, terms, values, texts, safe_rebuild=false)
  puts "-->> destroy_and_rebuild_index done"
  return_val
end

def update_xapian_index
  ActsAsXapian.update_index(flush_to_disk=false, verbose=false)
end

# Copy the xapian index created in create_fixtures_xapian_index to a temporary
# copy at the same level and point xapian at the copy
def get_fixtures_xapian_index
  # Create a base index for the fixtures if not already created
  x = create_fixtures_xapian_index
  binding.pry

  puts `cat /home/vagrant/alaveteli/lib/acts_as_xapian/xapiandbs/test/postlist.baseB`

  #binding.pry

  # Store whatever the xapian db path is originally
  original_xapian_path = Pathname.new(ActsAsXapian.db_path)

  #sleep 1
    puts File.read original_xapian_path + 'postlist.baseB'
  # Construct a temp path
  dirname, basename = original_xapian_path.split
  temp_path = dirname + basename.sub(basename.to_s, basename.to_s + '.temp')

  # Make sure the temp path doesn't exist
  FileUtils.remove_entry_secure(temp_path, force=true)

  puts ''
  puts "original_xapian_path --------"
  puts original_xapian_path
  puts ''
  puts `ls -al #{original_xapian_path}`

  puts ''
  puts "temp_path --------"
  puts temp_path
  puts ''
  puts `ls -al #{temp_path}`
  puts ''

  # Copy the original db to the temp path

  #begin
    FileUtils.cp_r(original_xapian_path, temp_path)
  #rescue Errno::ENOENT => e
    puts ''
    puts "original_xapian_path after rescue --------"
    puts original_xapian_path
    puts ''
    puts `ls -al #{original_xapian_path}`

    puts ''
    puts "temp_path after rescue --------"
    puts temp_path
    puts ''
    puts `ls -al #{temp_path}`
    puts ''

    #raise e
  #end


  # puts "cp --------"
  # puts `cp -r #{$original_xapian_path} #{temp_path}`

  # Make the temp db the new db to use
  ActsAsXapian.db_path = temp_path
end

# Create a clean xapian index based on the fixture files and the raw_email data.
def create_fixtures_xapian_index
  load_raw_emails_data
  destroy_and_rebuild_xapian_index
end
