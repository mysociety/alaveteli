bash "run bundle install in app directory" do
  cwd node[:root]
  code "bundle install"
end
