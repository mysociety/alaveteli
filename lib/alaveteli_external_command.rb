require 'external_command'

module AlaveteliExternalCommand
  UnknownProgram = Class.new(ArgumentError)
  Error = Class.new(StandardError)
  Unterminated = Class.new(Error)
  Timeout = Class.new(Error)
  Crash = Class.new(Error)

  class << self
    # Final argument can be a hash of options.
    # Valid options are:
    # :append_to - string to append the output of the process to
    # :append_errors_to - string to append the errors produced by the process to
    # :stdin_string - stdin string to pass to the process
    # :binary_output - boolean flag for treating the output as binary or text
    #                  encoded with the default external encoding (only
    #                  significant in ruby 1.9 and above)
    # :binary_input - boolean flag for treating the input as binary or as text
    #                 encoded with the default external encoding (only
    #                 significant in ruby 1.9 and above)
    # :memory_limit - maximum amount of memory (in bytes) available to the
    #                 process
    # :timeout - maximum amount of time (in s) to allow the process to run for
    # :env - hash of environment variables to set for the process
    def run!(program_name, *args)
      opts = args.extract_options!

      path = find_program(program_name)
      xc = ExternalCommand.new(path, *args)
      begin
        xc.run
      rescue ExternalCommand::ChildUnterminated => e
        raise Unterminated, e.message
      end

      if !xc.exited
        raise Timeout, xc.err if xc.timed_out
        raise Crash, xc.err
      elsif xc.status != 0
        raise Error, xc.err
      elsif opts.key?(:append_to)
        opts[:append_to] << "\n\n"
      else
        xc.out
      end
    end

    # Run an external program, and return its output. Standard error is
    # suppressed unless the program fails (i.e. returns a non-zero exit status).
    # If the program fails, returns nil and writes any error to stderr.
    def run(program_name, *args)
      opts = args.extract_options!
      run!(program_name, *args, opts)

    rescue Unterminated => e
      $stderr.puts(e.message)
    rescue Timeout => e
      $stderr.puts(%Q[External Command: "#{program_name} #{args.join(' ')}" ] \
                   "timed out at #{opts[:timeout]}s")
      $stderr.print(e.message)
    rescue Crash => e
      $stderr.puts(%Q[External Command: "#{program_name} #{args.join(' ')}" ] \
                   'exited abnormally')
      $stderr.print(e.message)
    rescue Error => e
      $stderr.puts(%Q[External Command: "#{program_name} #{args.join(' ')}" ] \
                   'error from command')
      $stderr.print(e.message)
    end

    def find_program(program_name)
      return program_name if program_name =~ %r(^/)

      search_path = AlaveteliConfiguration.utility_search_path
      search_path.each do |d|
        path = File.join(d, program_name)
        return path if File.file?(path) && File.executable?(path)
      end
      raise ArgumnetError, "Could not find #{program_name} in any of " \
        "#{search_path.join(', ')}"
    end

    def exist?(program_name)
      find_program(program_name).present?
    rescue UnknownProgram
      false
    end
  end
end
