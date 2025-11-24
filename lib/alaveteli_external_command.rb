require 'external_command'

class AlaveteliExternalCommand
  def self.run(program_name, *args)
    new(program_name).run(*args)
  end

  attr_reader :program_name, :command_args

  def initialize(program_name)
    @program_name = program_name
  end

  def add_args(*command_args)
    @command_args = command_args
    self
  end

  # Final argument can be a hash of options.
  # Valid options are:
  # :append_to - string to append the output of the process to
  # :append_errors_to - string to append the errors produced by the process to
  # :stdin_string - stdin string to pass to the process
  # :binary_output - boolean flag for treating the output as binary or text encoded with
  #                   the default external encoding (only significant in ruby 1.9 and above)
  # :binary_input - boolean flag for treating the input as binary or as text encoded with
  #                   the default external encoding (only significant in ruby 1.9 and above)
  # :memory_limit - maximum amount of memory (in bytes) available to the process
  # :timeout - maximum amount of time (in s) to allow the process to run for
  # :env - hash of environment variables to set for the process
  def run(*args)
    # Run an external program, and return its output.
    # Standard error is suppressed unless the program
    # fails (i.e. returns a non-zero exit status).
    # If the program fails, returns nil and writes any error to stderr.
    # TODO: calling code should be able to specify error stream - may want to log it or
    # otherwise act upon it.
    opts = {}
    if !args.empty? && args.last.is_a?(Hash)
      opts = args.last
    end

    program_path = find_program!
    xc = ExternalCommand.new(program_path, *command_args, *args)
    begin
      xc.run
    rescue ExternalCommand::ChildUnterminated => e
      $stderr.puts(e.message)
      return nil
    end

    if !xc.exited
      # Crash or timeout
      if xc.timed_out
        $stderr.puts(%Q[External Command: "#{program_name} #{args.join(' ')}" timed out at #{opts[:timeout]}s])
      else
        $stderr.puts(%Q[External Command: "#{program_name} #{args.join(' ')}" exited abnormally])
      end
      $stderr.print(xc.err)
      return nil

    elsif xc.status != 0
      # Error
      $stderr.puts(%Q[External Command: Error from command "#{program_name} #{args.join(' ')}":])
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

  def exist?
    find_program.present?
  end

  private

  def find_program
    return program_name if program_name =~ %r(^/)

    search_paths.each do |d|
      path = File.join(d, program_name)
      return path if File.file?(path) && File.executable?(path)
    end

    false
  end

  def find_program!
    find_program || raise(
      "Could not find #{program_name} in any of #{search_paths.join(', ')}"
    )
  end

  def search_paths
    paths = AlaveteliConfiguration.utility_search_path
    paths = ENV['PATH'].split(':') if paths.empty?
    paths
  end
end
