# -*- encoding : utf-8 -*-
class CreateTranslationTables < ActiveRecord::Migration
  def self.up
    fields = { :name => :text,
               :short_name => :text,
               :request_email => :text,
               :url_name => :text,
               :notes => :text,
               :first_letter => :string,
               :publication_scheme => :text }
    PublicBody.create_translation_table!(fields)

    # copy current values across to default locale
    PublicBody.all.each do |publicbody|
      publicbody.translated_attributes.each do |a, default|
        value = publicbody.read_attribute(a)
        unless value.nil?
          publicbody.send(:"#{a}=", value)
        end
      end
      publicbody.save!
    end
  end


  def self.down
    PublicBody.drop_translation_table!
  end
end
