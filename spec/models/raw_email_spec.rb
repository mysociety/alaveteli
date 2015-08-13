# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: raw_emails
#
#  id :integer          not null, primary key
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RawEmail do

  def roundtrip_data(raw_email, data)
    raw_email.data = data
    raw_email.save!
    raw_email.reload
    raw_email.data
  end

  describe 'data' do

    it 'roundtrips data unchanged' do
      raw_email = FactoryGirl.create(:incoming_message).raw_email
      data = roundtrip_data(raw_email, "Hello, world!")
      expect(data).to eq("Hello, world!")
    end

    it 'returns an unchanged binary string with a valid encoding if the data is non-ascii and non-utf-8' do
      raw_email = FactoryGirl.create(:incoming_message).raw_email
      data = roundtrip_data(raw_email, "\xA0")

      if data.respond_to?(:encoding)
        expect(data.encoding.to_s).to eq('ASCII-8BIT')
        expect(data.valid_encoding?).to be true
        data = data.force_encoding('UTF-8')
      end
      expect(data).to eq("\xA0")
    end

  end

  describe 'data_as_text' do

    it 'returns a utf-8 string with a valid encoding if the data is non-ascii and non-utf8' do
      raw_email = FactoryGirl.create(:incoming_message).raw_email
      roundtrip_data(raw_email, "\xA0ccc")
      data_as_text = raw_email.data_as_text
      expect(data_as_text).to eq("ccc")
      if data_as_text.respond_to?(:encoding)
        expect(data_as_text.encoding.to_s).to eq('UTF-8')
        expect(data_as_text.valid_encoding?).to be true
      end
    end

  end

end
