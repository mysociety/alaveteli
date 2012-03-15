node.default["root"] = File.join(File.dirname(__FILE__), "../../../../")
node.default["user"] = ENV['SUDO_USER'] || ENV['USERNAME']
node.default["group"] = ENV['SUDO_USER'] || ENV['USERNAME']
node.default["database_prefix"] = "foi"
