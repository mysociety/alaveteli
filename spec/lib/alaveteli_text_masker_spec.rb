# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AlaveteliTextMasker do

  let(:class_instance) { Class.new { include AlaveteliTextMasker }.new }

  describe '#apply_masks' do

    context 'applying censor rules' do

      before do
        @cheese_censor_rule = FactoryGirl.build(:censor_rule,
                                                :text => 'Stilton',
                                                :replacement => 'Jarlsberg')
        @colour_censor_rule = FactoryGirl.build(:censor_rule,
                                                :text => 'blue',
                                                :replacement => 'yellow')
        @regex_censor_rule = FactoryGirl.build(:censor_rule,
                                               :text => 'm[a-z][a-z][a-z]e',
                                               :replacement => 'cat',
                                               :regexp => true)
        @censor_rules = [@cheese_censor_rule,
                         @colour_censor_rule,
                         @regex_censor_rule]
      end

      it "does nothing to a JPEG" do
        data = "There was a mouse called Stilton, he wished that he was blue."

        result = class_instance.apply_masks(data,
                                            "image/jpeg",
                                            :censor_rules => @censor_rules)

        expect(result).
          to eq("There was a mouse called Stilton, he wished that he was blue.")
      end

      it "replaces censor text in Word documents" do
        data = "There was a mouse called Stilton, he wished that he was blue."
        result = class_instance.apply_masks(data,
                                            "application/vnd.ms-word",
                                            :censor_rules => @censor_rules)
        expect(result).
          to eq("There was a xxxxx called xxxxxxx, he wished that he was xxxx.")
      end

      it 'handles multibyte characters in binary file types as binary data' do
        data = 'á mouse'.force_encoding("ASCII-8BIT")
        @regex_censor_rule.text = 'á'
        result = class_instance.apply_masks(data,
                                            "application/octet-stream",
                                            :censor_rules => @censor_rules)
        expect(result).to eq('xx mouse')
      end

      it "applies censor rules to HTML files" do
        data = "There was a mouse called Stilton, he wished that he was blue."
        result = class_instance.apply_masks(data,
                                            'text/html',
                                            :censor_rules => @censor_rules)
        expect(result).
          to eq("There was a cat called Jarlsberg, he wished that he was yellow.")
      end

    end

    context 'applying masks to binary' do

      it "replaces ASCII email addresses in Word documents" do
        data = "His email was foo@bar.com"
        result = class_instance.apply_masks(data, "application/vnd.ms-word")
        expect(result).to eq("His email was xxx@xxx.xxx")
      end


      it "replaces UCS-2 addresses in Word documents" do
        data = "His email was f\000o\000o\000@\000b\000a\000r\000.\000c\000o\000m\000, indeed"
        expected = "His email was x\000x\000x\000@\000x\000x\000x\000.\000x\000x\000x\000, indeed"
        result = class_instance.apply_masks(data, "application/vnd.ms-word")
        expect(result).to eq(expected)
      end

    end

    context 'applying masks to PDF' do

      def pdf_replacement_test(use_ghostscript_compression)
        config = MySociety::Config.load_default
        previous = config['USE_GHOSTSCRIPT_COMPRESSION']
        config['USE_GHOSTSCRIPT_COMPRESSION'] = use_ghostscript_compression
        orig_pdf = load_file_fixture('tfl.pdf')
        pdf = orig_pdf.dup

        orig_text = MailHandler.get_attachment_text_one_file('application/pdf', pdf)
        expect(orig_text).to match(/foi@tfl.gov.uk/)

        result = class_instance.apply_masks(pdf, "application/pdf")

        masked_text = MailHandler.get_attachment_text_one_file('application/pdf', result)
        expect(masked_text).not_to match(/foi@tfl.gov.uk/)
        expect(masked_text).to match(/xxx@xxx.xxx.xx/)
        config['USE_GHOSTSCRIPT_COMPRESSION'] = previous
      end

      it "replaces everything in PDF files using pdftk" do
        pdf_replacement_test(false)
      end

      it "replaces everything in PDF files using ghostscript" do
        pdf_replacement_test(true)
      end

      it "does not produce zero length output if pdftk silently fails" do
        orig_pdf = load_file_fixture('psni.pdf')
        pdf = orig_pdf.dup
        result = class_instance.apply_masks(pdf, "application/pdf")
        expect(result).not_to eq("")
      end

      it 'returns the uncensored original if there is nothing to censor' do
        pdf = load_file_fixture('interesting.pdf')
        result = class_instance.apply_masks(pdf, "application/pdf")
        expect(result).to eq(pdf)
      end

      it 'keeps the uncensored original if uncompression of a PDF fails' do
        orig_pdf = load_file_fixture('tfl.pdf')
        pdf = orig_pdf.dup
        allow(class_instance).to receive(:uncompress_pdf){ nil }
        result = class_instance.apply_masks(pdf, "application/pdf")
        expect(result).to eq(orig_pdf)
      end

      it 'uses the uncompressed PDF text if re-compression of a compressed PDF fails' do
        orig_pdf = load_file_fixture('tfl.pdf')
        pdf = orig_pdf.dup
        allow(class_instance).to receive(:uncompress_pdf){ "something about foi@tfl.gov.uk" }
        allow(class_instance).to receive(:compress_pdf){ nil }
        result = class_instance.apply_masks(pdf, "application/pdf")
        expect(result).to match "something about xxx@xxx.xxx.xx"
      end

    end

    context 'applying masks to text' do

      it "applies hard-coded privacy rules to HTML files" do
        data = "http://test.host/c/cheese"
        result = class_instance.apply_masks(data, 'text/html')
        expect(result).to eq("[Alaveteli login link]")
      end

      it 'replaces a simple email address' do
        data = "the address is test@example.com"
        expected = "the address is [email address]"
        result = class_instance.apply_masks(data, 'text/html', {})
        expect(result).to eq(expected)
      end

      it 'replaces a mobile phone number prefixed with "Mobile"' do
        data = "the mobile is Mobile 55555 555555"
        expected = "the mobile is [mobile number]"
        result = class_instance.apply_masks(data, 'text/html', {})
        expect(result).to eq(expected)
      end

      it 'replaces a mobile phone number prefixed with "Mob Tel"' do
        data = "the mobile is Mob Tel: 55555 555 555"
        expected = "the mobile is [mobile number]"
        result = class_instance.apply_masks(data, 'text/html', {})
        expect(result).to eq(expected)
      end

      it 'replaces a mobile phone number prefixed with "Mob/Fax:"' do
        data = "the mobile is Mob/Fax: 55555 555555"
        expected = "the mobile is [mobile number]"
        result = class_instance.apply_masks(data, 'text/html', {})
        expect(result).to eq(expected)
      end

      it "replaces an Alaveteli login link" do
        data = "the login link is http://test.host/c/ekfmsdfkm"
        expected = "the login link is [Alaveteli login link]"
        result = class_instance.apply_masks(data, 'text/html', {})
        expect(result).to eq(expected)
      end

      it "replaces a https Alaveteli login link" do
        data = "the login link is https://test.host/c/ekfmsdfkm"
        expected = "the login link is [Alaveteli login link]"
        result = class_instance.apply_masks(data, 'text/html', {})
        expect(result).to eq(expected)
      end

      it "applies censor rules to text" do
        data = "here is a mouse"
        expected = "here is a cat"

        censor_rule = FactoryGirl.build(:censor_rule,
                                        :text => 'mouse',
                                        :replacement => 'cat')

        result = class_instance.apply_masks(data,
                                            'text/html',
                                            :censor_rules => [censor_rule])
        expect(result).to eq(expected)
      end

      it 'applies extra masks to text' do
        data = "here is a mouse"
        expected = "here is a cat"
        mask = { :to_replace => 'mouse', :replacement => 'cat'}
        result = class_instance.apply_masks(data, 'text/html', :masks => [mask])
        expect(result).to eq(expected)
      end

    end

  end

end
