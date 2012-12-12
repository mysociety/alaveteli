def file_fixture_name(file_name)
    return File.join(RSpec.configuration.fixture_path, "files", file_name)
end

def load_file_fixture(file_name, as_binary=false)
    file_name = file_fixture_name(file_name)
    content = File.open(file_name, 'r') do |file|
        if as_binary
            file.set_encoding(Encoding::BINARY) if file.respond_to?(:set_encoding)
        end
        file.read
    end
    return content
end
