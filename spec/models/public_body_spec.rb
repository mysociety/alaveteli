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
    
    it "should cope with same url_name across multiple locales" do
        PublicBody.with_locale(:es) do
            # use the unique spanish name to retrieve and edit
            body = PublicBody.find_by_url_name_with_historic('etgq')
            body.short_name = 'tgq' # Same as english version
            body.save! 
    
            # now try to retrieve it
            body = PublicBody.find_by_url_name_with_historic('tgq')
            body.id.should == public_bodies(:geraldine_public_body).id
            body.name.should == "El A Geraldine Quango"
        end
    end
end

describe PublicBody, " when dealing public body locales" do
    it "shouldn't fail if it internal_admin_body was created in a locale other than the default" do
        # first time, do it with the non-default locale
        PublicBody.with_locale(:es) do
            PublicBody.internal_admin_body
        end

        # second time
        lambda {PublicBody.internal_admin_body }.should_not raise_error(ActiveRecord::RecordInvalid)
    end
end

describe PublicBody, " when loading CSV files" do
    before(:each) do
        # InternalBody is created the first time it's accessed, which happens sometimes during imports,
        # depending on the tag used. By accessing it here before every test, it doesn't disturb our checks later on
        PublicBody.internal_admin_body
    end
    
    it "should import even if no email is provided" do
        errors, notes = PublicBody.import_csv("1,aBody", '', 'replace', true, 'someadmin') # true means dry run
        errors.should == []
        notes.size.should == 2
        notes[0].should == "line 1: creating new authority 'aBody' (locale: en):\n\t{\"name\":\"aBody\"}"
        notes[1].should =~ /Notes: Some  bodies are in database, but not in CSV file:\n(    [A-Za-z ]+\n)*You may want to delete them manually.\n/
    end
    
    it "should do a dry run successfully" do
        original_count = PublicBody.count

        csv_contents = load_file_fixture("fake-authority-type.csv")
        errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', true, 'someadmin') # true means dry run
        errors.should == []
        notes.size.should == 4
        notes[0..2].should == [
            "line 1: creating new authority 'North West Fake Authority' (locale: en):\n\t\{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\"\}", 
            "line 2: creating new authority 'Scottish Fake Authority' (locale: en):\n\t\{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\"\}", 
            "line 3: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t\{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\"\}",
        ]
        notes[3].should =~ /Notes: Some  bodies are in database, but not in CSV file:\n(    [A-Za-z ]+\n)*You may want to delete them manually.\n/

        PublicBody.count.should == original_count
    end

    it "should do full run successfully" do
        original_count = PublicBody.count

        csv_contents = load_file_fixture("fake-authority-type.csv")
        errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', false, 'someadmin') # false means real run
        errors.should == []
        notes.size.should == 4
        notes[0..2].should == [
            "line 1: creating new authority 'North West Fake Authority' (locale: en):\n\t\{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\"\}", 
            "line 2: creating new authority 'Scottish Fake Authority' (locale: en):\n\t\{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\"\}", 
            "line 3: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t\{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\"\}",
        ]
        notes[3].should =~ /Notes: Some  bodies are in database, but not in CSV file:\n(    [A-Za-z ]+\n)*You may want to delete them manually.\n/

        PublicBody.count.should == original_count + 3
    end

    it "should do imports without a tag successfully" do
        original_count = PublicBody.count
        
        csv_contents = load_file_fixture("fake-authority-type.csv")
        errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', false, 'someadmin') # false means real run
        errors.should == []
        notes.size.should == 4
        notes[0..2].should == [
            "line 1: creating new authority 'North West Fake Authority' (locale: en):\n\t\{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\"\}", 
            "line 2: creating new authority 'Scottish Fake Authority' (locale: en):\n\t\{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\"\}", 
            "line 3: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t\{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\"\}",
        ]
        notes[3].should =~ /Notes: Some  bodies are in database, but not in CSV file:\n(    [A-Za-z ]+\n)*You may want to delete them manually.\n/
        PublicBody.count.should == original_count + 3
    end

    it "should handle a field list and fields out of order" do
        original_count = PublicBody.count

        csv_contents = load_file_fixture("fake-authority-type-with-field-names.csv")
        errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', true, 'someadmin') # true means dry run
        errors.should == []
        notes.size.should == 4
        notes[0..2].should == [
            "line 2: creating new authority 'North West Fake Authority' (locale: en):\n\t\{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\",\"home_page\":\"http://northwest.org\"\}", 
            "line 3: creating new authority 'Scottish Fake Authority' (locale: en):\n\t\{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\",\"home_page\":\"http://scottish.org\",\"tag_string\":\"scottish\"\}", 
            "line 4: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t\{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\",\"tag_string\":\"fake aTag\"\}",
        ]
        notes[3].should =~ /Notes: Some  bodies are in database, but not in CSV file:\n(    [A-Za-z ]+\n)*You may want to delete them manually.\n/

        PublicBody.count.should == original_count
    end
    
    it "should import tags successfully when the import tag is not set" do
        csv_contents = load_file_fixture("fake-authority-type-with-field-names.csv")
        errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', false, 'someadmin') # false means real run

        PublicBody.find_by_name('North West Fake Authority').tag_array_for_search.should == []
        PublicBody.find_by_name('Scottish Fake Authority').tag_array_for_search.should == ['scottish']
        PublicBody.find_by_name('Fake Authority of Northern Ireland').tag_array_for_search.should == ['aTag', 'fake']

        # Import again to check the 'add' tag functionality works
        new_tags_file = load_file_fixture('fake-authority-add-tags.rb')
        errors, notes = PublicBody.import_csv(new_tags_file, '', 'add', false, 'someadmin') # false means real run

        # Check tags were added successfully
        PublicBody.find_by_name('North West Fake Authority').tag_array_for_search.should == ['aTag']
        PublicBody.find_by_name('Scottish Fake Authority').tag_array_for_search.should == ['aTag', 'scottish']
        PublicBody.find_by_name('Fake Authority of Northern Ireland').tag_array_for_search.should == ['aTag', 'fake']
    end

    it "should import tags successfully when the import tag is set" do
        csv_contents = load_file_fixture("fake-authority-type-with-field-names.csv")
        errors, notes = PublicBody.import_csv(csv_contents, 'fake', 'add', false, 'someadmin') # false means real run

        # Check new bodies were imported successfully
        PublicBody.find_by_name('North West Fake Authority').tag_array_for_search.should == ['fake']
        PublicBody.find_by_name('Scottish Fake Authority').tag_array_for_search.should == ['fake', 'scottish']
        PublicBody.find_by_name('Fake Authority of Northern Ireland').tag_array_for_search.should == ['aTag', 'fake']
        
        # Import again to check the 'replace' tag functionality works
        new_tags_file = load_file_fixture('fake-authority-add-tags.rb')
        errors, notes = PublicBody.import_csv(new_tags_file, 'fake', 'replace', false, 'someadmin') # false means real run
        
        # Check tags were added successfully
        PublicBody.find_by_name('North West Fake Authority').tag_array_for_search.should == ['aTag']
        PublicBody.find_by_name('Scottish Fake Authority').tag_array_for_search.should == ['aTag']
        PublicBody.find_by_name('Fake Authority of Northern Ireland').tag_array_for_search.should == ['aTag', 'fake']
    end

    it "should create bodies with names in multiple locales" do
        original_count = PublicBody.count

        csv_contents = load_file_fixture("fake-authority-type-with-field-names.csv")
        errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', false, 'someadmin', [:en, :es])
        errors.should == []
        notes.size.should == 7
        notes[0..5].should == [
            "line 2: creating new authority 'North West Fake Authority' (locale: en):\n\t{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\",\"home_page\":\"http://northwest.org\"}", 
            "line 2: creating new authority 'North West Fake Authority' (locale: es):\n\t{\"name\":\"Autoridad del Nordeste\"}", 
            "line 3: creating new authority 'Scottish Fake Authority' (locale: en):\n\t{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\",\"home_page\":\"http://scottish.org\",\"tag_string\":\"scottish\"}",
            "line 3: creating new authority 'Scottish Fake Authority' (locale: es):\n\t{\"name\":\"Autoridad Escocesa\"}",
            "line 4: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\",\"tag_string\":\"fake aTag\"}",
            "line 4: creating new authority 'Fake Authority of Northern Ireland' (locale: es):\n\t{\"name\":\"Autoridad Irlandesa\"}",
        ]
        notes[6].should =~ /Notes: Some  bodies are in database, but not in CSV file:\n(    [A-Za-z ]+\n)*You may want to delete them manually.\n/

        PublicBody.count.should == original_count + 3
        
        # XXX Not sure why trying to do a PublicBody.with_locale fails here. Seems related to 
        # the way categories are loaded every time from the PublicBody class. For now we just
        # test some translation was done.
        body = PublicBody.find_by_name('North West Fake Authority')
        body.translated_locales.map{|l|l.to_s}.sort.should == ["en", "es"]
    end

    it "should not fail if a locale is not found in the input file" do
        original_count = PublicBody.count

        csv_contents = load_file_fixture("fake-authority-type-with-field-names.csv")
        # Depending on the runtime environment (Ruby version? OS?) the list of available locales
        # is made of strings or symbols, so we use 'en' here as a string to test both scenarios.
        # See https://github.com/sebbacon/alaveteli/issues/193
        errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', true, 'someadmin', ['en', :xx]) # true means dry run
        errors.should == []
        notes.size.should == 4
        notes[0..2].should == [
            "line 2: creating new authority 'North West Fake Authority' (locale: en):\n\t{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\",\"home_page\":\"http://northwest.org\"}",
            "line 3: creating new authority 'Scottish Fake Authority' (locale: en):\n\t{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\",\"home_page\":\"http://scottish.org\",\"tag_string\":\"scottish\"}", 
            "line 4: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\",\"tag_string\":\"fake aTag\"}",
        ]
        notes[3].should =~ /Notes: Some  bodies are in database, but not in CSV file:\n(    [A-Za-z ]+\n)*You may want to delete them manually.\n/

        PublicBody.count.should == original_count
    end
end
