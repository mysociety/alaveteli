# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: public_bodies
#
#  id                                     :integer          not null, primary key
#  name                                   :text             not null
#  short_name                             :text             default(""), not null
#  request_email                          :text             not null
#  version                                :integer          not null
#  last_edit_editor                       :string(255)      not null
#  last_edit_comment                      :text             not null
#  created_at                             :datetime         not null
#  updated_at                             :datetime         not null
#  url_name                               :text             not null
#  home_page                              :text             default(""), not null
#  notes                                  :text             default(""), not null
#  first_letter                           :string(255)      not null
#  publication_scheme                     :text             default(""), not null
#  api_key                                :string(255)      not null
#  info_requests_count                    :integer          default(0), not null
#  disclosure_log                         :text             default(""), not null
#  info_requests_successful_count         :integer
#  info_requests_not_held_count           :integer
#  info_requests_overdue_count            :integer
#  info_requests_visible_classified_count :integer
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PublicBody do

  describe '#translations_attributes=' do

    context 'translation_attrs is a Hash' do

      it 'does not persist translations' do
        body = FactoryGirl.create(:public_body)
        body.translations_attributes = { :es => { :locale => 'es',
                                                  :name => 'El Body' } }

        expect(PublicBody.find(body.id).translations.size).to eq(1)
      end

      it 'creates a new translation' do
        body = FactoryGirl.create(:public_body)
        body.translations_attributes = { :es => { :locale => 'es',
                                                  :name => 'El Body' } }
        body.save
        body.reload
        expect(body.name(:es)).to eq('El Body')
      end

      it 'updates an existing translation' do
        body = FactoryGirl.create(:public_body)
        body.translations_attributes = { 'es' => { :locale => 'es',
                                                   :name => 'El Body' } }
        body.save

        body.translations_attributes = { 'es' => { :id => body.translation_for(:es).id,
                                                   :locale => 'es',
                                                   :name => 'Renamed' } }
        body.save
        expect(body.name(:es)).to eq('Renamed')
      end

      it 'updates an existing translation and creates a new translation' do
        body = FactoryGirl.create(:public_body)
        body.translations.create(:locale => 'es',
                                 :name => 'El Body')

        expect(body.translations.size).to eq(2)

        body.translations_attributes = {
          'es' => { :id => body.translation_for(:es).id,
                    :locale => 'es',
                    :name => 'Renamed' },
          'fr' => { :locale => 'fr',
                    :name => 'Le Body' }
        }

        expect(body.translations.size).to eq(3)
        I18n.with_locale(:es) { expect(body.name).to eq('Renamed') }
        I18n.with_locale(:fr) { expect(body.name).to eq('Le Body') }
      end

      it 'skips empty translations' do
        body = FactoryGirl.create(:public_body)
        body.translations.create(:locale => 'es',
                                 :name => 'El Body')

        expect(body.translations.size).to eq(2)

        body.translations_attributes = {
          'es' => { :id => body.translation_for(:es).id,
                    :locale => 'es',
                    :name => 'Renamed' },
          'fr' => { :locale => 'fr' }
        }

        expect(body.translations.size).to eq(2)
      end
    end
  end

  describe '#set_api_key' do

    it 'generates and sets an API key' do
      allow(SecureRandom).to receive(:base64).and_return('APIKEY')
      body = PublicBody.new
      body.set_api_key
      expect(body.api_key).to eq('APIKEY')
    end

    it 'does not overwrite an existing API key' do
      allow(SecureRandom).to receive(:base64).and_return('APIKEY')
      body = PublicBody.new(:api_key => 'EXISTING')
      body.set_api_key
      expect(body.api_key).to eq('EXISTING')
    end

  end

  describe '#set_api_key!' do

    it 'generates and sets an API key' do
      allow(SecureRandom).to receive(:base64).and_return('APIKEY')
      body = PublicBody.new
      body.set_api_key!
      expect(body.api_key).to eq('APIKEY')
    end

    it 'overwrites an existing API key' do
      allow(SecureRandom).to receive(:base64).and_return('APIKEY')
      body = PublicBody.new(:api_key => 'EXISTING')
      body.set_api_key!
      expect(body.api_key).to eq('APIKEY')
    end

  end

  describe  'when generating json for the api' do
    before do
      @public_body = PublicBody.new(:name => 'Marmot Appreciation Society',
                                    :short_name => 'MAS',
                                    :request_email => 'marmots@flourish.org',
                                    :last_edit_editor => 'test',
                                    :last_edit_comment => '',
                                    :info_requests_count => 10,
                                    :info_requests_successful_count => 2,
                                    :info_requests_not_held_count   => 2,
                                    :info_requests_overdue_count    => 3,
                                    :info_requests_visible_classified_count => 3)
    end

    it 'should return info about request counts' do
      expect(@public_body.json_for_api).to eq({ :name => 'Marmot Appreciation Society',
                                            :notes => "",
                                            :publication_scheme => "",
                                            :short_name => "MAS",
                                            :tags => [],
                                            :updated_at => nil,
                                            :url_name => "mas",
                                            :created_at => nil,
                                            :home_page => "http://www.flourish.org",
                                            :id => nil,
                                            :info => {
                                              :requests_count => 10,
                                              :requests_successful_count => 2,
                                              :requests_not_held_count   => 2,
                                              :requests_overdue_count    => 3,
                                              :requests_visible_classified_count => 3,
                                            }
                                            })
    end
  end

end

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
    expect(@public_body.tag_string).to eq('stilton emmental')

    expect(@public_body.has_tag?('stilton')).to be true
    expect(@public_body.has_tag?('emmental')).to be true
    expect(@public_body.has_tag?('jarlsberg')).to be false
  end

  it 'should strip spaces from tag strings' do
    @public_body.tag_string = ' chesire  lancashire'
    expect(@public_body.tag_string).to eq('chesire lancashire')
  end

  it 'should work with other white space, such as tabs and new lines' do
    @public_body.tag_string = "chesire\n\tlancashire"
    expect(@public_body.tag_string).to eq('chesire lancashire')
  end

  it 'changing tags should remove presence of the old ones' do
    @public_body.tag_string = 'stilton'
    expect(@public_body.tag_string).to eq('stilton')

    expect(@public_body.has_tag?('stilton')).to be true
    expect(@public_body.has_tag?('jarlsberg')).to be false

    @public_body.tag_string = 'jarlsberg'
    expect(@public_body.tag_string).to eq('jarlsberg')

    expect(@public_body.has_tag?('stilton')).to be false
    expect(@public_body.has_tag?('jarlsberg')).to be true
  end

  it 'should be able to append tags' do
    expect(@public_body.tag_string).to eq('')
    @public_body.add_tag_if_not_already_present('cheddar')

    expect(@public_body.tag_string).to eq('cheddar')
    expect(@public_body.has_tag?('cheddar')).to be true
  end

  it 'should ignore repeat tags' do
    @public_body.tag_string = 'stilton stilton'
    expect(@public_body.tag_string).to eq('stilton')
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
    expect(@public_body.tag_string).to eq('wondrous cheese:green')

    expect(@public_body.has_tag?('cheese:green')).to be false
    expect(@public_body.has_tag?('cheese')).to be true
    expect(@public_body.get_tag_values('cheese')).to eq(['green'])

    expect(@public_body.get_tag_values('wondrous')).to eq([])
    lambda {
      expect(@public_body.get_tag_values('notthere')).to raise_error(PublicBody::TagNotFound)
    }
  end

  it 'should cope with colons in value' do
    @public_body.tag_string = 'url:http://www.flourish.org'
    expect(@public_body.tag_string).to eq('url:http://www.flourish.org')

    expect(@public_body.has_tag?('url')).to be true
    expect(@public_body.get_tag_values('url')).to eq(['http://www.flourish.org'])
  end

  it 'should allow multiple tags of the same sort' do
    @public_body.tag_string = 'url:http://www.theyworkforyou.com/ url:http://www.fixmystreet.com/'
    expect(@public_body.has_tag?('url')).to be true
    expect(@public_body.get_tag_values('url')).to eq(['http://www.theyworkforyou.com/', 'http://www.fixmystreet.com/'])
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
    expect(found).to eq([ @geraldine ])
  end

  it 'should be able to find when there are multiple tags in one body, without returning duplicates' do
    found = PublicBody.find_by_tag('coney')
    expect(found).to eq([ @humpadink ])
  end
end

describe PublicBody, " when making up the URL name" do
  before do
    @public_body = PublicBody.new
  end

  it 'should remove spaces, and make lower case' do
    @public_body.name = 'Some Authority'
    expect(@public_body.url_name).to eq('some_authority')
  end

  it 'should not allow a numeric name' do
    @public_body.name = '1234'
    expect(@public_body.url_name).to eq('body')
  end
end

describe PublicBody, " when saving" do
  before do
    @public_body = PublicBody.new
  end

  def set_default_attributes(public_body)
    public_body.name = "Testing Public Body"
    public_body.short_name = "TPB"
    public_body.request_email = "request@localhost"
    public_body.last_edit_editor = "*test*"
    public_body.last_edit_comment = "This is a test"
  end

  it "should not be valid without setting some parameters" do
    expect(@public_body).not_to be_valid
  end

  it "should not be valid with misformatted request email" do
    set_default_attributes(@public_body)
    @public_body.request_email = "requestBOOlocalhost"
    expect(@public_body).not_to be_valid
    expect(@public_body.errors[:request_email].size).to eq(1)
  end

  it "should save" do
    set_default_attributes(@public_body)
    @public_body.save!
  end

  it "should update first_letter" do
    set_default_attributes(@public_body)
    expect(@public_body.first_letter).to be_nil
    @public_body.save!
    expect(@public_body.first_letter).to eq('T')
  end

  it "should update first letter, even if it's a multibyte character" do
    pb = PublicBody.new(:name => 'åccents, lower-case',
                        :short_name => 'ALC',
                        :request_email => 'foo@localhost',
                        :last_edit_editor => 'test',
                        :last_edit_comment => '')
    expect(pb.first_letter).to be_nil
    pb.save!
    expect(pb.first_letter).to eq('Å')
  end

  it 'should save the first letter of a translation' do
    existing = FactoryGirl.create(:public_body, :first_letter => 'T', :name => 'Test body')
    I18n.with_locale(:es) { existing.update_attributes :name => 'Prueba body' }
    expect(PublicBody::Translation.
      where(:public_body_id => existing.id, :locale => :es).
      pluck('first_letter').first).to eq('P')
  end

  it 'should save the first letter of a translation, even when it is the same as the
        first letter in the default locale' do
    existing = FactoryGirl.create(:public_body, :first_letter => 'T', :name => 'Test body')
    I18n.with_locale(:es) { existing.update_attributes :name => existing.name }
    expect(PublicBody::Translation.
      where(:public_body_id => existing.id, :locale => :es).
      pluck('first_letter').first).to eq('T')
  end

  it 'should create a url_name for a translation' do
    existing = FactoryGirl.create(:public_body, :first_letter => 'T', :short_name => 'Test body')
    I18n.with_locale(:es) do
      existing.update_attributes :short_name => 'Prueba', :name => 'Prueba body'
      expect(existing.url_name).to eq('prueba')
    end
  end

  it "should not save if the url_name is already taken" do
    existing = FactoryGirl.create(:public_body)
    pb = PublicBody.new(existing.attributes)
    pb.valid?
    expect(pb.errors[:url_name].size).to eq(1)
  end

  it "should save the name when renaming an existing public body" do
    public_body = public_bodies(:geraldine_public_body)
    public_body.name = "Mark's Public Body"
    public_body.save!

    expect(public_body.name).to eq("Mark's Public Body")
  end

  it 'should update the right translation when in a locale with an underscore' do
    AlaveteliLocalization.set_locales('he_IL', 'he_IL')
    public_body = public_bodies(:humpadink_public_body)
    translation_count = public_body.translations.size
    public_body.name = 'Renamed'
    public_body.save!
    expect(public_body.translations.size).to eq(translation_count)
  end

  it 'should not create a new version when nothing has changed' do
    expect(@public_body.versions.size).to eq(0)
    set_default_attributes(@public_body)
    @public_body.save!
    expect(@public_body.versions.size).to eq(1)
    @public_body.save!
    expect(@public_body.versions.size).to eq(1)
  end

  it 'should create a new version if something has changed' do
    expect(@public_body.versions.size).to eq(0)
    set_default_attributes(@public_body)
    @public_body.save!
    expect(@public_body.versions.size).to eq(1)
    @public_body.name = 'Test'
    @public_body.save!
    expect(@public_body.versions.size).to eq(2)
  end

end

describe PublicBody, "when searching" do

  it "should find by existing url name" do
    body = PublicBody.find_by_url_name_with_historic('dfh')
    expect(body.id).to eq(3)
  end

  it "should find by historic url name" do
    body = PublicBody.find_by_url_name_with_historic('hdink')
    expect(body.id).to eq(3)
    expect(body.class.to_s).to eq('PublicBody')
  end

  it "should cope with not finding any" do
    body = PublicBody.find_by_url_name_with_historic('idontexist')
    expect(body).to be_nil
  end

  it "should cope with duplicate historic names" do
    body = PublicBody.find_by_url_name_with_historic('dfh')

    # create history with short name "mouse" twice in it
    body.short_name = 'Mouse'
    expect(body.url_name).to eq('mouse')
    body.save!
    body.request_email = 'dummy@localhost'
    body.save!
    # but a different name now
    body.short_name = 'Stilton'
    expect(body.url_name).to eq('stilton')
    body.save!

    # try and find by it
    body = PublicBody.find_by_url_name_with_historic('mouse')
    expect(body.id).to eq(3)
    expect(body.class.to_s).to eq('PublicBody')
  end

  it "should cope with same url_name across multiple locales" do
    I18n.with_locale(:es) do
      # use the unique spanish name to retrieve and edit
      body = PublicBody.find_by_url_name_with_historic('etgq')
      body.short_name = 'tgq' # Same as english version
      body.save!

      # now try to retrieve it
      body = PublicBody.find_by_url_name_with_historic('tgq')
      expect(body.id).to eq(public_bodies(:geraldine_public_body).id)
      expect(body.name).to eq("El A Geraldine Quango")
    end
  end

  it 'should not raise an error on a name with a single quote in it' do
    body = PublicBody.find_by_url_name_with_historic("belfast city council'")
  end
end

describe PublicBody, "when asked for the internal_admin_body" do
  before(:each) do
    # Make sure that there's no internal_admin_body before each of
    # these tests:
    PublicBody.connection.delete("DELETE FROM public_bodies WHERE url_name = 'internal_admin_body'")
    PublicBody.connection.delete("DELETE FROM public_body_translations WHERE url_name = 'internal_admin_body'")
  end

  it "should create the internal_admin_body if it didn't exist" do
    iab = PublicBody.internal_admin_body
    expect(iab).not_to be_nil
  end

  it "should find the internal_admin_body even if the default locale has changed since it was created" do
    with_default_locale("en") do
      I18n.with_locale(:en) do
        iab = PublicBody.internal_admin_body
        expect(iab).not_to be_nil
      end
    end
    with_default_locale("es") do
      I18n.with_locale(:es) do
        iab = PublicBody.internal_admin_body
        expect(iab).not_to be_nil
      end
    end
  end

end


describe PublicBody, " when dealing public body locales" do
  it "shouldn't fail if it internal_admin_body was created in a locale other than the default" do
    # first time, do it with the non-default locale
    I18n.with_locale(:es) do
      PublicBody.internal_admin_body
    end

    # second time
    expect {PublicBody.internal_admin_body }.not_to raise_error
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
    expect(errors).to eq([])
    expect(notes.size).to eq(2)
    expect(notes[0]).to eq("line 1: creating new authority 'aBody' (locale: en):\n\t{\"name\":\"aBody\"}")
    expect(notes[1]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)
  end

  it "should do a dry run successfully" do
    original_count = PublicBody.count

    csv_contents = normalize_string_to_utf8(load_file_fixture("fake-authority-type.csv"))
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', true, 'someadmin') # true means dry run
    expect(errors).to eq([])
    expect(notes.size).to eq(6)
    expect(notes[0..4]).to eq([
      "line 1: creating new authority 'North West Fake Authority' (locale: en):\n\t\{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\"\}",
      "line 2: creating new authority 'Scottish Fake Authority' (locale: en):\n\t\{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\"\}",
      "line 3: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t\{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\"\}",
      "line 4: creating new authority 'Gobierno de Aragón' (locale: en):\n\t\{\"name\":\"Gobierno de Arag\\u00f3n\",\"request_email\":\"spain_foi@localhost\"}",
      "line 5: creating new authority 'Nordic æøå' (locale: en):\n\t{\"name\":\"Nordic \\u00e6\\u00f8\\u00e5\",\"request_email\":\"no_foi@localhost\"}"
    ])
    expect(notes[5]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)

    expect(PublicBody.count).to eq(original_count)
  end

  it "should do full run successfully" do
    original_count = PublicBody.count

    csv_contents = normalize_string_to_utf8(load_file_fixture("fake-authority-type.csv"))
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', false, 'someadmin') # false means real run
    expect(errors).to eq([])
    expect(notes.size).to eq(6)
    expect(notes[0..4]).to eq([
      "line 1: creating new authority 'North West Fake Authority' (locale: en):\n\t\{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\"\}",
      "line 2: creating new authority 'Scottish Fake Authority' (locale: en):\n\t\{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\"\}",
      "line 3: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t\{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\"\}",
      "line 4: creating new authority 'Gobierno de Aragón' (locale: en):\n\t\{\"name\":\"Gobierno de Arag\\u00f3n\",\"request_email\":\"spain_foi@localhost\"}",
      "line 5: creating new authority 'Nordic æøå' (locale: en):\n\t{\"name\":\"Nordic \\u00e6\\u00f8\\u00e5\",\"request_email\":\"no_foi@localhost\"}"
    ])
    expect(notes[5]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)

    expect(PublicBody.count).to eq(original_count + 5)
  end

  it "should do imports without a tag successfully" do
    original_count = PublicBody.count

    csv_contents = normalize_string_to_utf8(load_file_fixture("fake-authority-type.csv"))
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', false, 'someadmin') # false means real run
    expect(errors).to eq([])
    expect(notes.size).to eq(6)
    expect(notes[0..4]).to eq([
      "line 1: creating new authority 'North West Fake Authority' (locale: en):\n\t\{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\"\}",
      "line 2: creating new authority 'Scottish Fake Authority' (locale: en):\n\t\{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\"\}",
      "line 3: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t\{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\"\}",
      "line 4: creating new authority 'Gobierno de Aragón' (locale: en):\n\t\{\"name\":\"Gobierno de Arag\\u00f3n\",\"request_email\":\"spain_foi@localhost\"}",
      "line 5: creating new authority 'Nordic æøå' (locale: en):\n\t{\"name\":\"Nordic \\u00e6\\u00f8\\u00e5\",\"request_email\":\"no_foi@localhost\"}"
    ])
    expect(notes[5]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)
    expect(PublicBody.count).to eq(original_count + 5)
  end

  it "should handle a field list and fields out of order" do
    original_count = PublicBody.count

    csv_contents = load_file_fixture("fake-authority-type-with-field-names.csv")
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', true, 'someadmin') # true means dry run
    expect(errors).to eq([])
    expect(notes.size).to eq(4)
    expect(notes[0..2]).to eq([
      "line 2: creating new authority 'North West Fake Authority' (locale: en):\n\t\{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\",\"home_page\":\"http://northwest.org\"\}",
      "line 3: creating new authority 'Scottish Fake Authority' (locale: en):\n\t\{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\",\"home_page\":\"http://scottish.org\",\"tag_string\":\"scottish\"\}",
      "line 4: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t\{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\",\"tag_string\":\"fake aTag\"\}",
    ])
    expect(notes[3]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)

    expect(PublicBody.count).to eq(original_count)
  end

  it "should import tags successfully when the import tag is not set" do
    csv_contents = load_file_fixture("fake-authority-type-with-field-names.csv")
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', false, 'someadmin') # false means real run

    expect(PublicBody.find_by_name('North West Fake Authority').tag_array_for_search).to eq([])
    expect(PublicBody.find_by_name('Scottish Fake Authority').tag_array_for_search).to eq(['scottish'])
    expect(PublicBody.find_by_name('Fake Authority of Northern Ireland').tag_array_for_search).to eq(['aTag', 'fake'])

    # Import again to check the 'add' tag functionality works
    new_tags_file = load_file_fixture('fake-authority-add-tags.csv')
    errors, notes = PublicBody.import_csv(new_tags_file, '', 'add', false, 'someadmin') # false means real run

    # Check tags were added successfully
    expect(PublicBody.find_by_name('North West Fake Authority').tag_array_for_search).to eq(['aTag'])
    expect(PublicBody.find_by_name('Scottish Fake Authority').tag_array_for_search).to eq(['aTag', 'scottish'])
    expect(PublicBody.find_by_name('Fake Authority of Northern Ireland').tag_array_for_search).to eq(['aTag', 'fake'])
  end

  it "should import tags successfully when the import tag is set" do
    csv_contents = load_file_fixture("fake-authority-type-with-field-names.csv")
    errors, notes = PublicBody.import_csv(csv_contents, 'fake', 'add', false, 'someadmin') # false means real run

    # Check new bodies were imported successfully
    expect(PublicBody.find_by_name('North West Fake Authority').tag_array_for_search).to eq(['fake'])
    expect(PublicBody.find_by_name('Scottish Fake Authority').tag_array_for_search).to eq(['fake', 'scottish'])
    expect(PublicBody.find_by_name('Fake Authority of Northern Ireland').tag_array_for_search).to eq(['aTag', 'fake'])

    # Import again to check the 'replace' tag functionality works
    new_tags_file = load_file_fixture('fake-authority-add-tags.csv')
    errors, notes = PublicBody.import_csv(new_tags_file, 'fake', 'replace', false, 'someadmin') # false means real run

    # Check tags were added successfully
    expect(PublicBody.find_by_name('North West Fake Authority').tag_array_for_search).to eq(['aTag', 'fake'])
    expect(PublicBody.find_by_name('Scottish Fake Authority').tag_array_for_search).to eq(['aTag', 'fake'])
    expect(PublicBody.find_by_name('Fake Authority of Northern Ireland').tag_array_for_search).to eq(['aTag', 'fake'])
  end


  context 'when the import tag is set' do

    context 'with a new body' do

      it 'appends the import tag when no tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, 'imported', 'add', false, 'someadmin')

        expected = %W(imported)
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

      it 'appends the import tag when a tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,first_tag second_tag,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, 'imported', 'add', false, 'someadmin')

        expected = %W(first_tag imported second_tag)
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

      it 'replaces with the import tag when no tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, 'imported', 'replace', false, 'someadmin')

        expected = %W(imported)
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

      it 'replaces with the import tag and tag_string when a tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,first_tag second_tag,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, 'imported', 'replace', false, 'someadmin')

        expected = %W(first_tag imported second_tag)
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

    end

    context 'an existing body without tags' do

      before do
        @body = FactoryGirl.create(:public_body, :name => 'Existing Body')
      end

      it 'will not import if there is an existing body without the tag' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }",,#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        errors, notes = PublicBody.import_csv(csv, 'imported', 'add', false, 'someadmin')

        expected = %W(imported)
        expect(errors).to include("error: line 2: Name Name is already taken for authority 'Existing Body'")
      end

    end

    context 'an existing body with tags' do

      before do
        @body = FactoryGirl.create(:public_body, :tag_string => 'imported first_tag second_tag')
      end

      it 'created with tags, different tags in csv, add import tag' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }","first_tag new_tag",#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, 'imported', 'add', false, 'someadmin')
        expected = %W(first_tag imported new_tag second_tag)
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

      it 'created with tags, different tags in csv, replace import tag' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }","first_tag new_tag",#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, 'imported', 'replace', false, 'someadmin')

        expected = %W(first_tag imported new_tag)
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

    end

  end

  context 'when the import tag is not set' do

    context 'with a new body' do

      it 'it is empty if no tag_string is set' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'add', false, 'someadmin')

        expected = []
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

      it 'uses the specified tag_string' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,first_tag,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'add', false, 'someadmin')

        expected = %W(first_tag)
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

      it 'replaces with empty if no tag_string is set' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'replace', false, 'someadmin')

        expected = []
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

      it 'replaces with the specified tag_string' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,first_tag,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'replace', false, 'someadmin')

        expected = %W(first_tag)
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

    end

    context 'with an existing body without tags' do

      before do
        @body = FactoryGirl.create(:public_body)
      end

      it 'appends when no tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }",,#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'add', false, 'someadmin')

        expected = []
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

      it 'appends when a tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }",new_tag,#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'add', false, 'someadmin')

        expected = %W(new_tag)
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

      it 'replaces when no tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }",,#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'replace', false, 'someadmin')

        expected = []
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

      it 'replaces when a tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }",new_tag,#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'replace', false, 'someadmin')

        expected = %W(new_tag)
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

    end

    describe 'with an existing body with tags' do

      before do
        @body = FactoryGirl.create(:public_body, :tag_string => 'first_tag second_tag')
      end

      it 'created with tags, different tags in csv, add tags' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }","first_tag new_tag",#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'add', false, 'someadmin')

        expected = %W(first_tag new_tag second_tag)
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

      it 'created with tags, different tags in csv, replace' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }","first_tag new_tag",#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'replace', false, 'someadmin')

        expected = %W(first_tag new_tag)
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

    end

  end

  it "should create bodies with names in multiple locales" do
    original_count = PublicBody.count

    csv_contents = load_file_fixture("fake-authority-type-with-field-names.csv")
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', false, 'someadmin', [:en, :es])
    expect(errors).to eq([])
    expect(notes.size).to eq(7)
    expect(notes[0..5]).to eq([
      "line 2: creating new authority 'North West Fake Authority' (locale: en):\n\t{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\",\"home_page\":\"http://northwest.org\"}",
      "line 2: creating new authority 'North West Fake Authority' (locale: es):\n\t{\"name\":\"Autoridad del Nordeste\"}",
      "line 3: creating new authority 'Scottish Fake Authority' (locale: en):\n\t{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\",\"home_page\":\"http://scottish.org\",\"tag_string\":\"scottish\"}",
      "line 3: creating new authority 'Scottish Fake Authority' (locale: es):\n\t{\"name\":\"Autoridad Escocesa\"}",
      "line 4: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\",\"tag_string\":\"fake aTag\"}",
      "line 4: creating new authority 'Fake Authority of Northern Ireland' (locale: es):\n\t{\"name\":\"Autoridad Irlandesa\"}",
    ])
    expect(notes[6]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)

    expect(PublicBody.count).to eq(original_count + 3)

    # TODO: Not sure why trying to do a I18n.with_locale fails here. Seems related to
    # the way categories are loaded every time from the PublicBody class. For now we just
    # test some translation was done.
    body = PublicBody.find_by_name('North West Fake Authority')
    expect(body.translated_locales.map{|l|l.to_s}.sort).to eq(["en", "es"])
  end

  it "should not fail if a locale is not found in the input file" do
    original_count = PublicBody.count

    csv_contents = load_file_fixture("fake-authority-type-with-field-names.csv")
    # Depending on the runtime environment (Ruby version? OS?) the list of available locales
    # is made of strings or symbols, so we use 'en' here as a string to test both scenarios.
    # See https://github.com/mysociety/alaveteli/issues/193
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', true, 'someadmin', ['en', :xx]) # true means dry run
    expect(errors).to eq([])
    expect(notes.size).to eq(4)
    expect(notes[0..2]).to eq([
      "line 2: creating new authority 'North West Fake Authority' (locale: en):\n\t{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\",\"home_page\":\"http://northwest.org\"}",
      "line 3: creating new authority 'Scottish Fake Authority' (locale: en):\n\t{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\",\"home_page\":\"http://scottish.org\",\"tag_string\":\"scottish\"}",
      "line 4: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\",\"tag_string\":\"fake aTag\"}",
    ])
    expect(notes[3]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)

    expect(PublicBody.count).to eq(original_count)
  end

  it "should be able to load CSV from a file as well as a string" do
    # Essentially the same code is used for import_csv_from_file
    # as import_csv, so this is just a basic check that
    # import_csv_from_file can load from a file at all. (It would
    # be easy to introduce a regression that broke this, because
    # of the confusing change in behaviour of CSV.parse between
    # Ruby 1.8 and 1.9.)
    original_count = PublicBody.count
    filename = file_fixture_name('fake-authority-type-with-field-names.csv')
    PublicBody.import_csv_from_file(filename, '', 'replace', false, 'someadmin')
    expect(PublicBody.count).to eq(original_count + 3)
  end

  it "should handle active record validation errors" do
    csv = <<-CSV
#name,request_email,short_name
Foobar,a@example.com,foobar
Foobar Test,b@example.com,foobar
CSV

    csv_contents = normalize_string_to_utf8(csv)
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', true, 'someadmin') # true means dry run

    expect(errors).to include("error: line 3: Url name URL name is already taken for authority 'Foobar Test'")
  end

  it 'has a default list of fields to import' do
    expected_fields = [
      ['name', '(i18n)<strong>Existing records cannot be renamed</strong>'],
      ['short_name', '(i18n)'],
      ['request_email', '(i18n)'],
      ['notes', '(i18n)'],
      ['publication_scheme', '(i18n)'],
      ['disclosure_log', '(i18n)'],
      ['home_page', ''],
      ['tag_string', '(tags separated by spaces)'],
    ]

    expect(PublicBody.csv_import_fields).to eq(expected_fields)
  end

  it 'allows you to override the default list of fields to import' do
    old_csv_import_fields = PublicBody.csv_import_fields.clone
    expected_fields = [
      ['name', '(i18n)<strong>Existing records cannot be renamed</strong>'],
      ['short_name', '(i18n)'],
    ]

    PublicBody.csv_import_fields = expected_fields

    expect(PublicBody.csv_import_fields).to eq(expected_fields)

    # Reset our change so that we don't affect other specs
    PublicBody.csv_import_fields = old_csv_import_fields
  end

  it 'allows you to append to the default list of fields to import' do
    old_csv_import_fields = PublicBody.csv_import_fields.clone
    expected_fields = [
      ['name', '(i18n)<strong>Existing records cannot be renamed</strong>'],
      ['short_name', '(i18n)'],
      ['request_email', '(i18n)'],
      ['notes', '(i18n)'],
      ['publication_scheme', '(i18n)'],
      ['disclosure_log', '(i18n)'],
      ['home_page', ''],
      ['tag_string', '(tags separated by spaces)'],
      ['a_new_field', ''],
    ]

    PublicBody.csv_import_fields << ['a_new_field', '']

    expect(PublicBody.csv_import_fields).to eq(expected_fields)

    # Reset our change so that we don't affect other specs
    PublicBody.csv_import_fields = old_csv_import_fields
  end

  it "should import translations for fields whose values are the same as the default locale's" do
    original_count = PublicBody.count

    csv_contents = load_file_fixture("multiple-locales-same-name.csv")

    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', true, 'someadmin', ['en', 'es']) # true means dry run
    expect(errors).to eq([])
    expect(notes.size).to eq(3)
    expect(notes[0..1]).to eq([
      "line 2: creating new authority 'Test' (locale: en):\n\t{\"name\":\"Test\",\"request_email\":\"test@test.es\",\"home_page\":\"http://www.test.es/\",\"tag_string\":\"37\"}",
      "line 2: creating new authority 'Test' (locale: es):\n\t{\"name\":\"Test\"}",
    ])
    expect(notes[2]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)

    expect(PublicBody.count).to eq(original_count)
  end
end

describe PublicBody do

  describe "calculated home page" do
    it "should return the home page verbatim if it's present" do
      public_body = PublicBody.new
      public_body.home_page = "http://www.example.com"
      expect(public_body.calculated_home_page).to eq("http://www.example.com")
    end

    it "should return the home page based on the request email domain if it has one" do
      public_body = PublicBody.new
      allow(public_body).to receive(:request_email_domain).and_return "public-authority.com"
      expect(public_body.calculated_home_page).to eq("http://www.public-authority.com")
    end

    it "should return nil if there's no home page and the email domain can't be worked out" do
      public_body = PublicBody.new
      allow(public_body).to receive(:request_email_domain).and_return nil
      expect(public_body.calculated_home_page).to be_nil
    end

    it "should ensure home page URLs start with http://" do
      public_body = PublicBody.new
      public_body.home_page = "example.com"
      expect(public_body.calculated_home_page).to eq("http://example.com")
    end

    it "should not add http when https is present" do
      public_body = PublicBody.new
      public_body.home_page = "https://example.com"
      expect(public_body.calculated_home_page).to eq("https://example.com")
    end
  end

  describe 'when asked for notes without html' do

    before do
      @public_body = PublicBody.new(:notes => 'some <a href="/notes">notes</a>')
    end

    it 'should remove simple tags from notes' do
      expect(@public_body.notes_without_html).to eq('some notes')
    end

  end

  describe '#site_administration?' do

    it 'is true when the body has the site_administration tag' do
      p = FactoryGirl.build(:public_body, :tag_string => 'site_administration')
      expect(p.site_administration?).to be true
    end

    it 'is false when the body does not have the site_administration tag' do
      p = FactoryGirl.build(:public_body)
      expect(p.site_administration?).to be false
    end

  end

  describe '#has_request_email?' do

    before do
      @body = PublicBody.new(:request_email => 'test@example.com')
    end

    it 'should return false if request_email is nil' do
      @body.request_email = nil
      expect(@body.has_request_email?).to eq(false)
    end

    it 'should return false if the request email is "blank"' do
      @body.request_email = 'blank'
      expect(@body.has_request_email?).to eq(false)
    end

    it 'should return false if the request email is an empty string' do
      @body.request_email = ''
      expect(@body.has_request_email?).to eq(false)
    end

    it 'should return true if the request email is an email address' do
      expect(@body.has_request_email?).to eq(true)
    end
  end

  describe '#special_not_requestable_reason' do

    before do
      @body = PublicBody.new
    end

    it 'should return true if the body is defunct' do
      allow(@body).to receive(:defunct?).and_return(true)
      expect(@body.special_not_requestable_reason?).to eq(true)
    end

    it 'should return true if FOI does not apply' do
      allow(@body).to receive(:not_apply?).and_return(true)
      expect(@body.special_not_requestable_reason?).to eq(true)
    end

    it 'should return false if the body is not defunct and FOI applies' do
      expect(@body.special_not_requestable_reason?).to eq(false)
    end
  end

end

describe PublicBody, " when override all public body request emails set" do
  it "should return the overridden request email" do
    expect(AlaveteliConfiguration).to receive(:override_all_public_body_request_emails).twice.and_return("catch_all_test_email@foo.com")
    @geraldine = public_bodies(:geraldine_public_body)
    expect(@geraldine.request_email).to eq("catch_all_test_email@foo.com")
  end
end

describe PublicBody, "when calculating statistics" do

  it "should not include unclassified or hidden requests in percentages" do
    with_hidden_and_successful_requests do
      totals_data = PublicBody.get_request_totals(n=3,
                                                  highest=true,
                                                  minimum_requests=1)
      # For the total number of requests, we still include
      # hidden or unclassified requests:
      expect(totals_data['public_bodies'][-1].name).to eq("Geraldine Quango")
      expect(totals_data['totals'][-1]).to eq(4)

      # However, for percentages, don't include the hidden or
      # unclassified requests.  So, for the Geraldine Quango
      # we've made sure that there are only two visible and
      # classified requests, one of which is successful, so the
      # percentage should be 50%:

      percentages_data = PublicBody.get_request_percentages(column='info_requests_successful_count',
                                                            n=3,
                                                            highest=false,
                                                            minimum_requests=1)
      geraldine_index = percentages_data['public_bodies'].index do |pb|
        pb.name == "Geraldine Quango"
      end

      expect(percentages_data['y_values'][geraldine_index]).to eq(50)
    end
  end

  it "should only return totals for those with at least a minimum number of requests" do
    minimum_requests = 1
    with_enough_info_requests = PublicBody.where(["info_requests_count >= ?",
                                                  minimum_requests]).length
    all_data = PublicBody.get_request_totals 4, true, minimum_requests
    expect(all_data['public_bodies'].length).to eq(with_enough_info_requests)
  end

  it "should only return percentages for those with at least a minimum number of requests" do
    with_hidden_and_successful_requests do
      # With minimum requests at 3, this should return nil
      # (corresponding to zero public bodies) since the only
      # public body with just more than 3 info requests (The
      # Geraldine Quango) has a hidden and an unclassified
      # request within this block:
      minimum_requests = 3
      with_enough_info_requests = PublicBody.where(["info_requests_visible_classified_count >= ?",
                                                    minimum_requests]).length
      all_data = PublicBody.get_request_percentages(column='info_requests_successful_count',
                                                    n=10,
                                                    true,
                                                    minimum_requests)
      expect(all_data).to be_nil
    end
  end

  it "should only return those with at least a minimum number of requests, but not tagged 'test'" do
    hpb = PublicBody.find_by_name 'Department for Humpadinking'

    original_tag_string = hpb.tag_string
    hpb.add_tag_if_not_already_present 'test'

    begin
      minimum_requests = 1
      with_enough_info_requests = PublicBody.where(["info_requests_count >= ?", minimum_requests])
      all_data = PublicBody.get_request_totals 4, true, minimum_requests
      expect(all_data['public_bodies'].length).to eq(3)
    ensure
      hpb.tag_string = original_tag_string
    end
  end

end

describe PublicBody, 'when asked for popular bodies' do

  it 'should return bodies correctly when passed the hyphenated version of the locale' do
    allow(AlaveteliConfiguration).to receive(:frontpage_publicbody_examples).and_return('')
    expect(PublicBody.popular_bodies('he-IL')).to eq([public_bodies(:humpadink_public_body)])
  end

end

describe PublicBody do

  describe '#is_requestable?' do

    before do
      @body = PublicBody.new(:request_email => 'test@example.com')
    end

    it 'should return false if the body is defunct' do
      allow(@body).to receive(:defunct?).and_return true
      expect(@body.is_requestable?).to eq(false)
    end

    it 'should return false if FOI does not apply' do
      allow(@body).to receive(:not_apply?).and_return true
      expect(@body.is_requestable?).to eq(false)
    end

    it 'should return false there is no request_email' do
      allow(@body).to receive(:has_request_email?).and_return false
      expect(@body.is_requestable?).to eq(false)
    end

    it 'should return true if the request email is an email address' do
      expect(@body.is_requestable?).to eq(true)
    end

  end

  describe '#is_followupable?' do

    before do
      @body = PublicBody.new(:request_email => 'test@example.com')
    end

    it 'should return false there is no request_email' do
      allow(@body).to receive(:has_request_email?).and_return false
      expect(@body.is_followupable?).to eq(false)
    end

    it 'should return true if the request email is an email address' do
      expect(@body.is_followupable?).to eq(true)
    end

  end

  describe '#not_requestable_reason' do

    before do
      @body = PublicBody.new(:request_email => 'test@example.com')
    end

    it 'should return "defunct" if the body is defunct' do
      allow(@body).to receive(:defunct?).and_return true
      expect(@body.not_requestable_reason).to eq('defunct')
    end

    it 'should return "not_apply" if FOI does not apply' do
      allow(@body).to receive(:not_apply?).and_return true
      expect(@body.not_requestable_reason).to eq('not_apply')
    end


    it 'should return "bad_contact" there is no request_email' do
      allow(@body).to receive(:has_request_email?).and_return false
      expect(@body.not_requestable_reason).to eq('bad_contact')
    end

    it 'should raise an error if the body is not defunct, FOI applies and has an email address' do
      expected_error = "not_requestable_reason called with type that has no reason"
      expect{ @body.not_requestable_reason }.to raise_error(expected_error)
    end

  end

  describe '#request_email' do
    context "when the email is set" do
      subject(:public_body) { FactoryGirl.create(:public_body, :request_email => "request@example.com") }

      it "should return the set email address" do
        expect(public_body.request_email).to eq("request@example.com")
      end

      it "should return a different email address when overridden in configuration" do
        allow(AlaveteliConfiguration).to receive(:override_all_public_body_request_emails).and_return("tester@example.com")
        expect(public_body.request_email).to eq("tester@example.com")
      end
    end

    context "when no email is set" do
      subject(:public_body) { FactoryGirl.create(:public_body, :request_email => "") }

      it "should return a blank email address" do
        expect(public_body.request_email).to be_blank
      end

      it "should still return a blank email address when overridden in configuration" do
        allow(AlaveteliConfiguration).to receive(:override_all_public_body_request_emails).and_return("tester@example.com")
        expect(public_body.request_email).to be_blank
      end
    end
  end
end

describe PublicBody::Translation do

  it 'requires a locale' do
    translation = PublicBody::Translation.new
    translation.valid?
    expect(translation.errors[:locale]).to eq(["can't be blank"])
  end

  it 'is valid if all required attributes are assigned' do
    translation = PublicBody::Translation.new(:locale => I18n.default_locale)
    expect(translation).to be_valid
  end

end
