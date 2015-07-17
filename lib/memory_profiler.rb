# -*- encoding : utf-8 -*-
# Taken from
# http://scottstuff.net/blog/2006/08/17/memory-leak-profiling-with-rails

# This is useful for finding memory leaks of the sort where a reference has
# been accidentally kept to an object when it wasn't intended to be. It
# is particularly useful if the leaking objects contain strings.
#
# You can enable it in config/environments/development.rb It then writes
# to log files in logs/memory_profiler*
#
# If you have :string_debug enabled, you might find this one liner useful. It
# compares the two most recent string dumps.
# strings `ls -1t *profiler_strings* | head --lines=1` |sort > a; strings `ls -1t *profiler_strings* | head --lines=2 | tail --lines=1` |sort > b; diff b a |less

class MemoryProfiler
  DEFAULTS = {:delay => 10, :string_debug => false}

  def self.start(opt={})
    opt = DEFAULTS.dup.merge(opt)

    Thread.new do
      prev = Hash.new(0)
      curr = Hash.new(0)
      curr_strings = []
      delta = Hash.new(0)

      file = File.open('log/memory_profiler.log','w')

      loop do
        begin
          GC.start
          curr.clear

          curr_strings = [] if opt[:string_debug]

          ObjectSpace.each_object do |o|
            curr[o.class] += 1 #Marshal.dump(o).size rescue 1
            if opt[:string_debug] and o.class == String
              curr_strings.push o
            end
          end

          if opt[:string_debug]
            File.open("log/memory_profiler_strings.log.#{Time.now.to_i}",'w') do |f|
              curr_strings.sort.each do |s|
                f.puts s
              end
            end
            curr_strings.clear
          end

          delta.clear
          (curr.keys + delta.keys).uniq.each do |k,v|
            delta[k] = curr[k]-prev[k]
          end

          file.puts "Top 20"
          delta.sort_by { |k,v| -v.abs }[0..19].sort_by { |k,v| -v}.each do |k,v|
            file.printf "%+5d: %s (%d)\n", v, k.name, curr[k] unless v == 0
          end
          file.flush

          delta.clear
          prev.clear
          prev.update curr
          GC.start
        rescue Exception => err
          $stderr.puts "** memory_profiler error: #{err}"
        end
        sleep opt[:delay]
      end
    end
  end
end
