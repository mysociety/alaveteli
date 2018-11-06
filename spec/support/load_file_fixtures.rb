# -*- encoding : utf-8 -*-
def file_fixture_name(file_name)
  File.join(RSpec.configuration.fixture_path, "files", file_name)
end

def load_file_fixture(file_name, mode = 'rb')
  file_name = file_fixture_name(file_name)
  File.open(file_name, mode) { |f| f.read } if File.exist?(file_name)
end

def read_described_class_fixture(fixture)
  base_path = described_class.name.underscore
  File.read(File.join(RSpec.configuration.fixture_path, base_path, fixture))
end

def read_described_template_fixture
  described_template = self.class.description.gsub(/\..*\.erb/, '')
  File.read(File.join(RSpec.configuration.fixture_path, described_template))
end
