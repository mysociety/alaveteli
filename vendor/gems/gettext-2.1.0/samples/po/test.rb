filename, to = ARGV
p filename
p to
Dir.glob("*/#{filename}.po").each do |path|
  data = IO.read(path)
  data.gsub!(/#{filename}/, to)
p  to_path = path.sub(/#{filename}/, to)
  File.open(to_path, "w") do |out|
    out.write data
  end
end
