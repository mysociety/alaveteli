def load_raw_emails_data
    raw_emails_yml = File.join(RSpec.configuration.fixture_path, "raw_emails.yml")
    for raw_email_id in YAML::load_file(raw_emails_yml).map{|k,v| v["id"]} do
        raw_email = RawEmail.find(raw_email_id)
        raw_email.data = load_file_fixture("raw_emails/%d.email" % [raw_email_id])
    end
end
