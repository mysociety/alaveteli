ARGV.each do |path|
  data = IO.read(path)
  data.gsub!(/license terms as Ruby\./, "license terms as Ruby or LGPL.")
  open(path, "w") do |out|
    out.write data
  end
end

