
namespace :submodules do

    desc "Check the status of the project's submodules"
    task :check => :environment do
        commit_info = `git submodule status`
        sha, repo, branch = commit_info.split(' ')
        case sha[0]
        when '+'
            $stderr.puts "Warning: Currently checked out submodule commit for #{repo}"
            $stderr.puts "does not match the commit expected by this version of Alaveteli."
            $stderr.puts "You can update it with 'git submodule update'."
            exit(1)
        when '-'
            $stderr.puts "Warning: Submodule #{repo} needs to be initialized."
            $stderr.puts "You can do this by running 'git submodule update --init'."
            exit(1)
        when 'U'
            $stderr.puts "Warning: Submodule #{repo} has merge conflicts."
            $stderr.puts "You'll probably need to resolve these to run Alaveteli."
            exit(1)
        else
            exit(0)
        end
    end

end
