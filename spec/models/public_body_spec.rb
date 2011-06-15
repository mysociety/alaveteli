require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PublicBody, " using tags" do 
    before do
        @public_body = PublicBody.new(:name => 'Aardvark Monitoring Service',
                                    :short_name => 'AMS',
                                    :request_email => 'foo@flourish.org',
                                    :last_edit_editor => 'test',
                                    :last_edit_comment => '')
    end

    it 'should correctly convert a tag string into tags' do 
        @public_body.tag_string = 'stilton emmental'
        @public_body.tag_string.should == 'stilton emmental'

        @public_body.has_tag?('stilton').should be_true
        @public_body.has_tag?('emmental').should be_true
        @public_body.has_tag?('jarlsberg').should be_false
    end

    it 'should strip spaces from tag strings' do
        @public_body.tag_string = ' chesire  lancashire'
        @public_body.tag_string.should == 'chesire lancashire'
    end

    it 'should work with other white space, such as tabs and new lines' do
        @public_body.tag_string = "chesire\n\tlancashire"
        @public_body.tag_string.should == 'chesire lancashire'
    end

    it 'changing tags should remove presence of the old ones' do
        @public_body.tag_string = 'stilton'
        @public_body.tag_string.should == 'stilton'

        @public_body.has_tag?('stilton').should be_true
        @public_body.has_tag?('jarlsberg').should be_false

        @public_body.tag_string = 'jarlsberg'
        @public_body.tag_string.should == 'jarlsberg'

        @public_body.has_tag?('stilton').should be_false
        @public_body.has_tag?('jarlsberg').should be_true
    end

    it 'should be able to append tags' do
        @public_body.tag_string.should == ''
        @public_body.add_tag_if_not_already_present('cheddar')

        @public_body.tag_string.should == 'cheddar'
        @public_body.has_tag?('cheddar').should be_true
    end

    it 'should ignore repeat tags' do
        @public_body.tag_string = 'stilton stilton'
        @public_body.tag_string.should == 'stilton'
    end
end

describe PublicBody, " using machine tags" do 
    before do
        @public_body = PublicBody.new(:name => 'Aardvark Monitoring Service',
                                    :short_name => 'AMS',
                                    :request_email => 'foo@flourish.org',
                                    :last_edit_editor => 'test',
                                    :last_edit_comment => '')
    end

    it 'should parse machine tags' do
        @public_body.tag_string = 'wondrous cheese:green'
        @public_body.tag_string.should == 'wondrous cheese:green'

        @public_body.has_tag?('cheese:green').should be_false
        @public_body.has_tag?('cheese').should be_true
        @public_body.get_tag_values('cheese').should == ['green']

        @public_body.get_tag_values('wondrous').should == []
        lambda {
            @public_body.get_tag_values('notthere').should raise_error(PublicBody::TagNotFound)
        }
    end

    it 'should cope with colons in value' do
        @public_body.tag_string = 'url:http://www.flourish.org'
        @public_body.tag_string.should == 'url:http://www.flourish.org'

        @public_body.has_tag?('url').should be_true
        @public_body.get_tag_values('url').should == ['http://www.flourish.org']
    end

    it 'should allow multiple tags of the same sort' do
        @public_body.tag_string = 'url:http://www.theyworkforyou.com/ url:http://www.fixmystreet.com/'
        @public_body.has_tag?('url').should be_true
        @public_body.get_tag_values('url').should == ['http://www.theyworkforyou.com/', 'http://www.fixmystreet.com/']
    end
end

describe PublicBody, "when finding_by_tags" do
    fixtures :public_bodies, :public_body_translations

    before do
         @geraldine = public_bodies(:geraldine_public_body)
         @geraldine.tag_string = 'rabbit'
         @humpadink = public_bodies(:humpadink_public_body)
         @humpadink.tag_string = 'coney:5678 coney:1234'
    end

    it 'should be able to find bodies by string' do
        found = PublicBody.find_by_tag('rabbit')
        found.should == [ @geraldine ]
    end

    it 'should be able to find when there are multiple tags in one body, without returning duplicates' do
        found = PublicBody.find_by_tag('coney')
        found.should == [ @humpadink ]
    end
end

describe PublicBody, " when making up the URL name" do 
    before do
        @public_body = PublicBody.new
    end

    it 'should remove spaces, and make lower case' do 
        @public_body.name = 'Some Authority'
        @public_body.url_name.should == 'some_authority'
    end

    it 'should not allow a numeric name' do 
        @public_body.name = '1234'
        @public_body.url_name.should == 'body'
    end
end
 
describe PublicBody, " when saving" do
    before do
        @public_body = PublicBody.new
    end

    it "should not be valid without setting some parameters" do
        @public_body.should_not be_valid
    end

    it "should not be valid with misformatted request email" do
        @public_body.name = "Testing Public Body"
        @public_body.short_name = "TPB"
        @public_body.request_email = "requestBOOlocalhost"
        @public_body.last_edit_editor = "*test*"
        @public_body.last_edit_comment = "This is a test"
        @public_body.should_not be_valid
        @public_body.should have(1).errors_on(:request_email)
    end

    it "should save" do
        @public_body.name = "Testing Public Body"
        @public_body.short_name = "TPB"
        @public_body.request_email = "request@localhost"
        @public_body.last_edit_editor = "*test*"
        @public_body.last_edit_comment = "This is a test"
        @public_body.save!
    end
    
    it "should update first_letter" do
        @public_body.name = "Testing Public Body"
        @public_body.short_name = "TPB"
        @public_body.request_email = "request@localhost"
        @public_body.last_edit_editor = "*test*"
        @public_body.last_edit_comment = "This is a test"
        
        @public_body.first_letter.should be_nil
        @public_body.save!
        @public_body.first_letter.should == 'T'
    end
end

describe PublicBody, "when searching" do
    fixtures :public_bodies, :public_body_translations, :public_body_versions

    it "should find by existing url name" do
        body = PublicBody.find_by_url_name_with_historic('dfh')
        body.id.should == 3
    end

    it "should find by historic url name" do
        body = PublicBody.find_by_url_name_with_historic('hdink')
        body.id.should == 3
        body.class.to_s.should == 'PublicBody'
    end

    it "should cope with not finding any" do
        body = PublicBody.find_by_url_name_with_historic('idontexist')
        body.should be_nil
    end

    it "should cope with duplicate historic names" do
        body = PublicBody.find_by_url_name_with_historic('dfh')

        # create history with short name "mouse" twice in it
        body.short_name = 'Mouse'
        body.url_name.should == 'mouse'
        body.save!
        body.request_email = 'dummy@localhost'
        body.save!
        # but a different name now
        body.short_name = 'Stilton'
        body.url_name.should == 'stilton'
        body.save!

        # try and find by it
        body = PublicBody.find_by_url_name_with_historic('mouse')
        body.id.should == 3
        body.class.to_s.should == 'PublicBody'
    end
end

describe PublicBody, " when loading CSV files" do
    it "should do a dry run successfully" do
        original_count = PublicBody.count

        csv_contents = load_file_fixture("fake-authority-type.csv")
        errors, notes = PublicBody.import_csv(csv_contents, 'fake', true, 'someadmin') # true means dry run
        errors.should == []
        notes.size.should == 3
        notes.should == ["line 1: new authority 'North West Fake Authority' with email north_west_foi@localhost", 
            "line 2: new authority 'Scottish Fake Authority' with email scottish_foi@localhost", 
            "line 3: new authority 'Fake Authority of Northern Ireland' with email ni_foi@localhost"]

        PublicBody.count.should == original_count
    end

    it "should do full run successfully" do
        original_count = PublicBody.count

        csv_contents = load_file_fixture("fake-authority-type.csv")
        errors, notes = PublicBody.import_csv(csv_contents, 'fake', false, 'someadmin') # false means real run
        errors.should == []
        notes.size.should == 3
        notes.should == ["line 1: new authority 'North West Fake Authority' with email north_west_foi@localhost", 
            "line 2: new authority 'Scottish Fake Authority' with email scottish_foi@localhost", 
            "line 3: new authority 'Fake Authority of Northern Ireland' with email ni_foi@localhost"]

        PublicBody.count.should == original_count + 3
    end
end



