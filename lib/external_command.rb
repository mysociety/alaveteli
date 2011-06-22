# Run an external command, capturing its stdout and stderr
# streams into variables.
#
# So it’s rather like the `backtick` built-in, except that:
#   - The command is run as-is, rather than being parsed by the shell;
#   - Standard error is also captured.
#
# After the run() method has been called, the instance variables
# out, err and status contain the contents of the process’s stdout,
# the contents of its stderr, and the exit status.
#
# Example usage:
#   require 'external_command'
#   xc = ExternalCommand("ls", "-l").run()
#   puts "Ran ls -l with exit status #{xc.status}"
#   puts "===STDOUT===\n#{xc.out}"
#   puts "===STDERR===\n#{xc.err}"
#
# The out and err attributes are writeable. If you assign
# a string, after calling the constructor and before calling
# run(), then the subprocess output/error will be appended
# to this string.

# <rant author="robin">
#   In any sane language, this would be implemented with a
#   single child process. The parent process would block on
#   select(), and when the child process terminated, the
#   select call would be interrupted by a CHLD signal
#   and return EINTR. Unfortunately Ruby goes out of its
#   way to prevent this from working, automatically restarting
#   the select call if EINTR is returned. Therefore we
#   use a parent-child-grandchild arrangement, where the
#   parent blocks on select() and the child blocks on
#   waitpid(). When the child detects that the grandchild
#   has finished, it writes to a pipe that’s included in
#   the parent’s select() for this purpose.
# </rant>

class ExternalCommand
    attr_accessor :out, :err
    attr_reader :status

    def initialize(cmd, *args)
        @cmd = cmd
        @args = args

        # Strings to collect stdout and stderr from the child process
        # These may be replaced by the caller, to append to existing strings.
        @out = ""
        @err = ""
        @fin = ""
    end

    def run()
        # Pipes for parent-child communication
        @out_read, @out_write = IO::pipe
        @err_read, @err_write = IO::pipe
        @fin_read, @fin_write = IO::pipe

        @pid = fork do
            # Here we’re in the child process.
            child_process
        end

        # Here we’re in the parent process.
        parent_process

        return self
    end

    private

    def child_process()
        # Reopen stdout and stderr to point at the pipes
        STDOUT.reopen(@out_write)
        STDERR.reopen(@err_write)

        # Close all the filehandles other than the ones we intend to use.
        ObjectSpace.each_object(IO) do |fh|
            fh.close unless (
                [STDOUT, STDERR, @fin_write].include?(fh) || fh.closed?)
        end

        Process::waitpid(fork { grandchild_process })
        @fin_write.puts($?.exitstatus.to_s)

        exit! 0
    end

    def grandchild_process()
        exec(@cmd, *@args)

        # This is only reached if the exec fails
        @err_write.print("Failed to exec: #{[@cmd, *@args].join(' ')}")
        exit! 99
    end

    def parent_process()
        # Close the writing ends of the pipes
        @out_write.close
        @err_write.close
        @fin_write.close

        @fhs = {@out_read => @out, @err_read => @err, @fin_read => @fin}

        while @fin.empty?
           ok = read_data
           if !ok
               raise "select() timed out even with a nil (infinite) timeout"
            end
        end

        while read_data(0)
            # Pull out any data that’s left in the pipes
        end

        Process::waitpid(@pid)
        @status = @fin.to_i
        @out_read.close
        @err_read.close
    end

    def read_data(timeout=nil)
        ready_array = IO.select(@fhs.keys, [], [], timeout)
        return false if ready_array.nil?
        ready_array[0].each do |fh|
            begin
                @fhs[fh] << fh.readpartial(8192)
            rescue EOFError
                @fhs.delete fh
            end
        end
        return true
    end
end
