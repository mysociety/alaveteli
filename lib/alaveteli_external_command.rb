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
            
            xc = ExternalCommand.new(program_name, *args)
            if opts.has_key? :append_to
                xc.out = opts[:append_to]
            end
            xc.run()
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
