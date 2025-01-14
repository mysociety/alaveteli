def file_fixture_name(file_name)
  Rails.root.join("spec", "fixtures", "files", file_name).to_s
end

def load_file_fixture(file_name, mode = 'rb')
  file_name = file_fixture_name(file_name)
  File.open(file_name, mode, &:read) if File.exist?(file_name)
end

def read_described_class_fixture(fixture)
  base_path = described_class.name.underscore
  File.read(Rails.root.join("spec", "fixtures", base_path, fixture))
end

def read_described_template_fixture
  described_template = self.class.top_level_description.gsub(/\..*\.erb/, '')
  File.read(Rails.root.join("spec", "fixtures", described_template))
end
