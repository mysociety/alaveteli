# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe ApplicationMailer do

  context 'when using plugins' do

    def set_base_views
      ApplicationMailer.class_eval do
        @previous_view_paths = self.view_paths.dup
        self.view_paths = [File.join(Rails.root, 'spec', 'fixtures', 'theme_views', 'core')]
      end
    end

    def add_mail_methods(method_names)
      method_names.each{ |method_name| ApplicationMailer.send(:define_method, method_name){ mail } }
    end

    def remove_mail_methods(method_names)
      method_names.each do |method_name|
        if ApplicationMailer.respond_to?(method_name)
          ApplicationMailer.send(:remove_method, method_name)
        end
      end
    end

    def prepend_theme_views(theme_name)
      ApplicationMailer.class_eval do
        prepend_view_path File.join(Rails.root, 'spec', 'fixtures', 'theme_views', theme_name)
      end
    end

    def append_theme_views(theme_name)
      ApplicationMailer.class_eval do
        append_view_path File.join(Rails.root, 'spec', 'fixtures', 'theme_views', theme_name)
      end
    end

    def reset_views
      ApplicationMailer.class_eval do
        self.view_paths = @previous_view_paths
      end
    end

    def create_multipart_method(method_name)
      ApplicationMailer.send(:define_method, method_name) do
        attachments['original.eml'] = 'xxx'
        mail
      end
    end

    before do
      set_base_views
      add_mail_methods(['simple', 'theme_only', 'core_only', 'neither'])
    end

    describe 'when a plugin prepends its mail templates to the view paths' do

      it 'should render a theme template in preference to a core template' do
        prepend_theme_views('theme_one')
        @mail = ApplicationMailer.simple
        expect(@mail.body).to match('Theme simple')
      end

      it 'should render the template provided by the theme if no template is available in core' do
        prepend_theme_views('theme_one')
        @mail = ApplicationMailer.theme_only
        expect(@mail.body).to match('Theme only')
      end

      it 'should render the template provided by core if there is no theme template' do
        prepend_theme_views('theme_one')
        @mail = ApplicationMailer.core_only
        expect(@mail.body).to match('Core only')
      end

      it 'should render an empty body if the template is in neither core nor theme' do
        prepend_theme_views('theme_one')
        @mail = ApplicationMailer.neither
        expect(@mail.body).to be_empty
      end

      it 'should render a multipart email using a theme template' do
        prepend_theme_views('theme_one')
        create_multipart_method('multipart_theme_only')
        @mail = ApplicationMailer.multipart_theme_only
        expect(@mail.parts.size).to eq(2)
        message_part = @mail.parts[0].to_s
        expect(message_part).to match("Theme multipart")
      end

      it 'should render a multipart email using a core template' do
        prepend_theme_views('theme_one')
        create_multipart_method('multipart_core_only')
        @mail = ApplicationMailer.multipart_core_only
        expect(@mail.parts.size).to eq(2)
        message_part = @mail.parts[0].to_s
        expect(message_part).to match("Core multipart")
      end

    end

    describe 'when a plugin appends its mail templates to the view paths' do

      it 'should render a core template in preference to a theme template' do
        append_theme_views('theme_one')
        @mail = ApplicationMailer.simple
        expect(@mail.body).to match('Core simple')
      end

      it 'should render the template provided by the theme if no template is available in core' do
        append_theme_views('theme_one')
        @mail = ApplicationMailer.theme_only
        expect(@mail.body).to match('Theme only')
      end

      it 'should render the template provided by core if there is no theme template' do
        append_theme_views('theme_one')
        @mail = ApplicationMailer.core_only
        expect(@mail.body).to match('Core only')
      end

      it 'should render an empty body if the template is in neither core nor theme' do
        append_theme_views('theme_one')
        @mail = ApplicationMailer.neither
        expect(@mail.body).to be_empty
      end

      it 'should render a multipart email using a core template' do
        append_theme_views('theme_one')
        create_multipart_method('multipart_core_only')
        @mail = ApplicationMailer.multipart_core_only
        expect(@mail.parts.size).to eq(2)
        message_part = @mail.parts[0].to_s
        expect(message_part).to match("Core multipart")
      end

      it 'should render a multipart email using a theme template' do
        append_theme_views('theme_one')
        create_multipart_method('multipart_theme_only')
        @mail = ApplicationMailer.multipart_theme_only
        expect(@mail.parts.size).to eq(2)
        message_part = @mail.parts[0].to_s
        expect(message_part).to match("Theme multipart")
      end

    end

    after do
      reset_views
      remove_mail_methods(['simple', 'theme_only', 'core_only', 'neither', 'multipart'])
    end
  end

end
