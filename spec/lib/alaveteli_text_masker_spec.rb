# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AlaveteliTextMasker do
    include AlaveteliTextMasker

    describe :apply_masks! do

        describe 'when applying censor rules' do

            before do
                @cheese_censor_rule = FactoryGirl.build(:censor_rule, :text => 'Stilton',
                                                                      :replacement => 'Jarlsberg')
                @colour_censor_rule = FactoryGirl.build(:censor_rule, :text => 'blue',
                                                                      :replacement => 'yellow')
                @regex_censor_rule = FactoryGirl.build(:censor_rule, :text => 'm[a-z][a-z][a-z]e',
                                                                     :replacement => 'cat',
                                                                     :regexp => true)
                @censor_rules = [@cheese_censor_rule, @colour_censor_rule, @regex_censor_rule]
            end

            it "should do nothing to a JPEG" do
                data = "There was a mouse called Stilton, he wished that he was blue."
                apply_masks!(data, "image/jpeg", :censor_rules => @censor_rules)
                data.should == "There was a mouse called Stilton, he wished that he was blue."
            end

            it "should replace censor text in Word documents" do
                data = "There was a mouse called Stilton, he wished that he was blue."
                apply_masks!(data, "application/vnd.ms-word", :censor_rules => @censor_rules)
                data.should == "There was a xxxxx called xxxxxxx, he wished that he was xxxx."
            end

            it 'should handle multibyte characters correctly' do
                data = 'á mouse'
                @regex_censor_rule.text = 'á'
                apply_masks!(data, "application/octet-stream", :censor_rules => @censor_rules).should == 'x mouse'
            end

            it "should apply censor rules to HTML files" do
                data = "There was a mouse called Stilton, he wished that he was blue."
                apply_masks!(data, 'text/html', :censor_rules => @censor_rules)
                data.should == "There was a cat called Jarlsberg, he wished that he was yellow."
            end

        end

        it "should replace ASCII email addresses in Word documents" do
            data = "His email was foo@bar.com"
            expected = "His email was xxx@xxx.xxx"
            apply_masks!(data, "application/vnd.ms-word")
            data.should == expected
         end


        it "should replace UCS-2 addresses in Word documents" do
            data = "His email was f\000o\000o\000@\000b\000a\000r\000.\000c\000o\000m\000, indeed"
            apply_masks!(data, "application/vnd.ms-word")
            data.should == "His email was x\000x\000x\000@\000x\000x\000x\000.\000x\000x\000x\000, indeed"
        end

        def pdf_replacement_test(use_ghostscript_compression)
            config = MySociety::Config.load_default()
            previous = config['USE_GHOSTSCRIPT_COMPRESSION']
            config['USE_GHOSTSCRIPT_COMPRESSION'] = use_ghostscript_compression
            orig_pdf = load_file_fixture('tfl.pdf')
            pdf = orig_pdf.dup

            orig_text = MailHandler.get_attachment_text_one_file('application/pdf', pdf)
            orig_text.should match(/foi@tfl.gov.uk/)

            apply_masks!(pdf, "application/pdf")

            masked_text = MailHandler.get_attachment_text_one_file('application/pdf', pdf)
            masked_text.should_not match(/foi@tfl.gov.uk/)
            masked_text.should match(/xxx@xxx.xxx.xx/)
            config['USE_GHOSTSCRIPT_COMPRESSION'] = previous
        end

        it "should replace everything in PDF files using pdftk" do
            pdf_replacement_test(false)
        end

        it "should replace everything in PDF files using ghostscript" do
            pdf_replacement_test(true)
        end

        it "should not produce zero length output if pdftk silently fails" do
            orig_pdf = load_file_fixture('psni.pdf')
            pdf = orig_pdf.dup
            apply_masks!(pdf, "application/pdf")
            pdf.should_not == ""
        end

        it 'should keep the uncensored original if uncompression of a PDF fails' do
            orig_pdf = load_file_fixture('tfl.pdf')
            pdf = orig_pdf.dup
            stub!(:uncompress_pdf).and_return nil
            apply_masks!(pdf, "application/pdf")
            pdf.should == orig_pdf
        end

        it 'should use the uncompressed PDF text if re-compression of a compressed PDF fails' do
            orig_pdf = load_file_fixture('tfl.pdf')
            pdf = orig_pdf.dup
            stub!(:uncompress_pdf).and_return "something about foi@tfl.gov.uk"
            stub!(:compress_pdf).and_return nil
            apply_masks!(pdf, "application/pdf")
            pdf.should match "something about xxx@xxx.xxx.xx"
        end

        it "should apply hard-coded privacy rules to HTML files" do
            data = "http://test.host/c/cheese"
            apply_masks!(data, 'text/html')
            data.should == "[Alaveteli login link]"
        end

        it 'should replace a simple email address' do
            expected = "the address is [email address]"
            apply_masks!("the address is test@example.com", 'text/html', {}).should == expected
        end

        it 'should replace a mobile phone number prefixed with "Mobile"' do
            expected = "the mobile is [mobile number]"
            apply_masks!("the mobile is Mobile 55555 555555", 'text/html', {}).should == expected
        end

        it 'should replace a mobile phone number prefixed with "Mob Tel"' do
            expected = "the mobile is [mobile number]"
            apply_masks!("the mobile is Mob Tel: 55555 555 555", 'text/html', {}).should == expected
        end

        it 'should replace a mobile phone number prefixed with "Mob/Fax:"' do
            expected = "the mobile is [mobile number]"
            apply_masks!("the mobile is Mob/Fax: 55555 555555", 'text/html', {}).should == expected
        end

        it "should replace an Alaveteli login link" do
            expected = "the login link is [Alaveteli login link]"
            apply_masks!("the login link is http://test.host/c/ekfmsdfkm", 'text/html', {}).should == expected
        end

        it "should replace a https Alaveteli login link" do
            expected = "the login link is [Alaveteli login link]"
            apply_masks!("the login link is https://test.host/c/ekfmsdfkm", 'text/html', {}).should == expected
        end

        it "should apply censor rules to text" do
            censor_rule = FactoryGirl.build(:censor_rule, :text => 'mouse', :replacement => 'cat')
            expected = "here is a cat"
            apply_masks!("here is a mouse", 'text/html', {:censor_rules => [ censor_rule ]}).should == expected
        end

        it 'should apply extra masks to text' do
            mask = {:to_replace => 'mouse', :replacement => 'cat'}
            expected = "here is a cat"
            apply_masks!("here is a mouse", 'text/html', {:masks => [ mask ]}).should == expected
        end

    end

end

