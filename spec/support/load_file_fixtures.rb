def file_fixture_name(filename)
  Rails.root.join("spec", "fixtures", "files", filename).to_s
end

def load_file_fixture(filename, mode = 'rb')
  filename = file_fixture_name(filename)
  File.open(filename, mode, &:read) if File.exist?(filename)
end

def read_described_class_fixture(fixture)
  base_path = described_class.name.underscore
  File.read(Rails.root.join("spec", "fixtures", base_path, fixture))
end

def read_described_template_fixture
  described_template = self.class.top_level_description.gsub(/\..*\.erb/, '')
  File.read(Rails.root.join("spec", "fixtures", described_template))
end
