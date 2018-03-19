# -*- encoding : utf-8 -*-
def file_fixture_name(file_name)
  File.join(RSpec.configuration.fixture_path, "files", file_name)
end

def load_file_fixture(file_name, mode = 'rb')
  file_name = file_fixture_name(file_name)
  File.open(file_name, mode) { |f| f.read } if File.exist?(file_name)
end
