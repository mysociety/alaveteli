class CreateTranslationTables < ActiveRecord::Migration[4.2] # 2.3
  class ::PublicBody
    # This has been removed from the model but is needed for this old migration
    # to work
    translates :notes
  end

  def self.up
    fields = { name: :text,
               short_name: :text,
               request_email: :text,
               url_name: :text,
               notes: :text,
               first_letter: :string,
               publication_scheme: :text }
    PublicBody.create_translation_table!(fields)

    # copy current values across to default locale
    PublicBody.all.each do |publicbody|
      publicbody.translated_attributes.each do |a, default|
        value = publicbody.read_attribute(a)
        publicbody.send(:"#{a}=", value) unless value.nil?
      end
      publicbody.save!
    end
  end


  def self.down
    PublicBody.drop_translation_table!
  end
end
