# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require "alaveteli_gettext/task_methods.rb"

describe "AlaveteliGetText::TaskMethods" do

  let(:dummy_class) { Class.new { extend AlaveteliGetText::TaskMethods } }
  let(:theme) { "alavetelitheme" }

  describe '#find_theme' do

    it 'returns the theme name if supplied' do
      expect(dummy_class.find_theme(theme)).to eq(theme)
    end

  end

  describe '#files_to_translate' do

    it 'returns a Rake::FileList' do
      expect(dummy_class.files_to_translate).to be_a(Rake::FileList)
    end

    it 'does not include the alaveteli pro files paths' do
      expect(dummy_class.files_to_translate).
        to_not include(dummy_class.pro_locale_path)
    end

    it 'does not include the theme file paths' do
      expect(dummy_class.files_to_translate).
        to_not include(dummy_class.theme_files_to_translate(theme))
    end

  end

  describe '#theme_files_to_translate' do

    it 'returns a Rake::FileList' do
      expect(dummy_class.theme_files_to_translate(theme)).
        to be_a(Rake::FileList)
    end

    it 'does not include the alaveteli pro locale path' do
      expect(dummy_class.theme_files_to_translate(theme)).
        to_not include(dummy_class.pro_locale_path)
    end

    it 'does not include the main project locale paths' do
      expect(dummy_class.theme_files_to_translate(theme)).
        to_not include(dummy_class.locale_path)
    end

  end

  describe '#pro_files_to_translate' do
    it 'returns a Rake::FileList' do
      expect(dummy_class.pro_files_to_translate).
        to be_a(Rake::FileList)
    end

    it 'does not include the main project locale paths' do
      expect(dummy_class.pro_files_to_translate).
        to_not include(dummy_class.locale_path)
    end

    it 'does not include the theme file paths' do
      expect(dummy_class.pro_files_to_translate).
        to_not include(dummy_class.theme_files_to_translate(theme))
    end
  end

  describe '#define_gettext_task' do

    before do
      # override the default Rake::CLEAN settings
      suppress_warnings do
        CLEAN = Rake::FileList[]
      end
    end

    it 'returns a Rake::Task object' do
      expect(
        dummy_class.define_gettext_task("test",
                                        "spec/fixtures/locale",
                                        dummy_class.files_to_translate)
      ).to be_a(Rake::Task)
    end

  end

  describe '#replace_version' do

    it 'should replace the Project-Id-Version with the supplied text' do
      input = '"Project-Id-Version: 0.0.1\n"'
      expected = "Project-Id-Version: alaveteli"

      expect(dummy_class.replace_version(input, "alaveteli")).to match(expected)
    end

  end

  private

  def suppress_warnings
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
  ensure
    $stderr = old_stderr
  end

end
