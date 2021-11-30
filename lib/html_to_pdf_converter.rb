require 'alaveteli_external_command'

##
# Wrapper class for wkhtmltopdf external command. Supports versions <= 0.11 and
# the current 0.12 release.
#
class HTMLtoPDFConverter
  def initialize(*args)
    @args = args
    @input, @output = args.pop(2)
  end

  def run
    command.run(*args)
  end

  def to_s
    [command.program_name, *command.command_args, *args].join(' ')
  end

  private

  def command
    self.class.command
  end

  def args
    [*@args, @input.path, @output.path]
  end

  class << self
    delegate :exist?, to: :base_command

    def command
      if version < Gem::Version.new('0.12')
        base_command
      else
        base_command.add_args(
          '--enable-local-file-access',
          '--no-images',
          '--load-media-error-handling', 'ignore',
          '--load-error-handling', 'skip'
        )
      end
    end

    private

    def version
      return unless exist?

      output = base_command.run('--version')
      Gem::Version.new(output.scan(/[\d\.]+/)[0])
    end

    def base_command
      AlaveteliExternalCommand.new('wkhtmltopdf')
    end
  end
end
