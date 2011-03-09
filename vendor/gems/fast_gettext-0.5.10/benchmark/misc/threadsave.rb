require 'benchmark'
BASELINE = 0
def test
  result = Benchmark.measure {1_000_000.times{ yield }}
  result.to_s.strip.split(' ').first.to_f - BASELINE
end

BASELINE = (test{})
Thread.current[:library_name]={}
other = "x"
puts "Ruby #{VERSION}"

puts "generic:"
puts "  Symbol: #{test{Thread.current[:library_name][:just_a_symbol]}}s"
puts "  String concat: #{test{Thread.current["xxxxxx"<<other.to_s]}}s"
puts "  String add: #{test{Thread.current["xxxxxx"+other.to_s]}}s"
puts "  String insert: #{test{Thread.current["xxxxxx#{other}"]}}s"

puts "single:"
puts "  Symbol: #{test{Thread.current[:long_unique_symbol]}}s"
puts "  String: #{test{Thread.current["xxxxxx"]}}s"