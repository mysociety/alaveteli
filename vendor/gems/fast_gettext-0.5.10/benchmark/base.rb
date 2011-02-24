require 'rubygems'
require 'benchmark'

RUNS = 50_0000
DEFAULTS = {:memory=>0}

def locale_folder(domain)
  path = case domain
  when 'test' then File.join(File.expand_path(File.dirname(__FILE__)),'..','spec','locale')
  when 'large' then File.join(File.expand_path(File.dirname(__FILE__)),'locale')
  end

  mo = File.join(path,'de','LC_MESSAGES',"#{domain}.mo")
  raise unless File.exist?(mo)
  path
end

def results_test(&block)
  print "#{(result(&block)).to_s.strip.split(' ').first}s / #{memory}K <-> "
end

def results_large
  print "#{(result {_('login') == 'anmelden'}).to_s.strip.split(' ').first}s / #{memory}K"
  puts ""
end

def result
  result =Benchmark.measure do
    RUNS.times do
      raise "not translated" unless yield
    end
  end
  result
end

def memory
  pid = Process.pid
  map = `pmap -d #{pid}`
  map.split("\n").last.strip.squeeze(' ').split(' ')[3].to_i - DEFAULTS[:memory]
end

DEFAULTS[:memory] = memory + 4 #4 => 0 for base calls