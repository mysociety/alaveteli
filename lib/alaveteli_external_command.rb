require 'external_command'

module AlaveteliExternalCommand
    class << self
        def run(program_name, *args)
            # Run an external program, and return its output.
            # Standard error is suppressed unless the program
            # fails (i.e. returns a non-zero exit status).
            opts = {}
            if !args.empty? && args[-1].is_a?(Hash)
                opts = args.pop
            end
            
            if program_name =~ %r(^/)
                program_path = program_name
            else
                utility_search_path = MySociety::Config.get("UTILITY_SEARCH_PATH", ["/usr/bin", "/usr/local/bin"])
                found = false
                utility_search_path.each do |d|
                    program_path = File.join(d, program_name)
                    if File.file? program_path and File.executable? program_path
                        found = true
                        break
                    end
                end
                 raise "Could not find #{program_name} in any of #{utility_search_path.join(', ')}" if !found
            end
            
            xc = ExternalCommand.new(program_path, *args)
            if opts.has_key? :append_to
                xc.out = opts[:append_to]
            end
            xc.run(opts[:stdin_string], opts[:env] || {})
            if xc.status != 0
                # Error
                $stderr.puts("Error from #{program_name} #{args.join(' ')}:")
                $stderr.print(xc.err)
                return nil
            else
                if opts.has_key? :append_to
                    opts[:append_to] << "\n\n"
                else
                    return xc.out
                end
            end
        end
    end
end
