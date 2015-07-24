# -*- encoding : utf-8 -*-
module Usage

  def usage_message message
    puts ''
    puts message
    puts ''
    exit 0
  end

  def check_for_env_vars(env_vars, example)
    missing = []
    env_vars.each do |env_var|
      unless ENV[env_var]
        missing << env_var
      end
    end
    if !missing.empty?
      usage = "Usage: This task requires #{env_vars.to_sentence} - missing #{missing.to_sentence}"
      if example
        usage += "\nExample: #{example}"
      end
      usage_message usage
    end
  end

end
