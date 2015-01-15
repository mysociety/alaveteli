require 'external_command'

module AlaveteliExternalCommand
    class << self
        # Final argument can be a hash of options.
        # Valid options are:
        # :append_to - string to append the output of the process to
        # :stdin_string - stdin string to pass to the process
        # :binary_output - boolean flag for treating the output as binary or text encoded with
        #                   the default external encoding (only significant in ruby 1.9 and above)
        # :binary_input - boolean flag for treating the input as binary or as text encoded with
        #                   the default external encoding (only significant in ruby 1.9 and above)
        # :memory_limit - maximum amount of memory (in bytes) available to the process
        # :timeout - maximum amount of time (in s) to allow the process to run for
        def run(program_name, *args)
            # Run an external program, and return its output.
            # Standard error is suppressed unless the program
            # fails (i.e. returns a non-zero exit status).
            opts = {}
            if !args.empty? && args.last.is_a?(Hash)
                opts = args.last
            end

            program_path = find_program(program_name)

            xc = ExternalCommand.new(program_path, *args)
            if opts.has_key? :append_to
                xc.out = opts[:append_to]
            end
            if opts.has_key? :binary_output
                xc.binary_output = opts[:binary_output]
            end
            if opts.has_key? :binary_input
                xc.binary_input = opts[:binary_input]
            end
            if opts.has_key? :memory_limit
                xc.memory_limit = opts[:memory_limit]
            end


            xc.run(opts[:stdin_string] || "", opts[:env] || {})

            if !xc.exited
                # Crash or timeout
                if xc.timed_out
                    $stderr.puts(%Q[Command "#{program_name} #{args.join(' ')}" timed out at #{opts[:timeout]}s])
                else
                    $stderr.puts(%Q[Command ""#{program_name} #{args.join(' ')}" exited abnormally])
                end
                $stderr.print(xc.err)
                return nil

            elsif xc.status != 0
                # Error
                $stderr.puts(%Q[Error from command "#{program_name} #{args.join(' ')}":])
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

        def find_program(program_name)
            if program_name =~ %r(^/)
                return program_name
            else
                search_path = AlaveteliConfiguration::utility_search_path
                search_path.each do |d|
                    program_path = File.join(d, program_name)
                    return program_name if File.file? program_path and File.executable? program_path
                end
                raise "Could not find #{program_name} in any of #{search_path.join(', ')}"
            end
        end
    end
end
