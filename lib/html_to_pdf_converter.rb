require 'alaveteli_external_command'

##
# Wrapper class for wkhtmltopdf external command. Supports versions <= 0.11
# only.
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
    [command.program_name, *args].join(' ')
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
      base_command
    end

    private

    def base_command
      AlaveteliExternalCommand.new('wkhtmltopdf')
    end
  end
end
