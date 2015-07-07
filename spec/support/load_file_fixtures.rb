# -*- encoding : utf-8 -*-
def file_fixture_name(file_name)
    return File.join(RSpec.configuration.fixture_path, "files", file_name)
end

def load_file_fixture(file_name)
    file_name = file_fixture_name(file_name)
    return File.open(file_name, 'rb') { |f| f.read }
end
