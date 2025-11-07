namespace :public_body do
  desc 'Exports all public bodies to an all-authorities.csv file'
  task export: :environment do
    output = Rails.root.join('cache', 'all-authorities.csv')
    FileUtils.mkdir_p(File.dirname(output))

    # Create a temporary file in the same directory, so we can
    # rename it atomically to the intended filename:
    tmp = Tempfile.new(File.basename(output), File.dirname(output))
    tmp.close

    data = PublicBodyCSV.export

    # Export all the public bodies to that temporary path, make it readable,
    # and rename it
    File.open(tmp.path, 'w') { |file| file.write(data) }
    FileUtils.chmod(0o0644, tmp.path)
    File.rename(tmp.path, output)
  end
end
