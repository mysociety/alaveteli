
namespace :submodules do

  desc "Check the status of the project's submodules"
  task :check => :environment do
    commit_info = `git submodule status commonlib`
    case commit_info[0,1]
    when '+'
      $stderr.puts "Error: Currently checked out submodule commit for commonlib"
      $stderr.puts "does not match the commit expected by this version of Alaveteli."
      $stderr.puts "You can update it with 'git submodule update'."
      exit(1)
    when '-'
      $stderr.puts "Error: Submodule commonlib needs to be initialized."
      $stderr.puts "You can do this by running 'git submodule update --init'."
      exit(1)
    when 'U'
      $stderr.puts "Error: Submodule commonlib has merge conflicts."
      $stderr.puts "You'll need to resolve these to run Alaveteli."
      exit(1)
    when ' '
      exit(0)
    else
      raise "Unexpected status character in response to 'git submodule status commonlib': #{commit_info[0,1]}"
    end
  end

end
