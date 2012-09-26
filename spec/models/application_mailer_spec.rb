require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe ApplicationMailer do

    context 'when using plugins' do

        def set_base_views
            ApplicationMailer.class_eval do
                @previous_view_paths = self.view_paths.dup
                self.view_paths.clear
                self.view_paths << File.join(Rails.root, 'spec', 'fixtures', 'theme_views', 'core')
            end
        end

        def add_mail_methods(method_names)
            method_names.each{ |method_name| ApplicationMailer.send(:define_method, method_name){} }
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
                view_paths.unshift File.join(Rails.root, 'spec', 'fixtures', 'theme_views', theme_name)
            end
        end

        def append_theme_views(theme_name)
            ApplicationMailer.class_eval do
                view_paths << File.join(Rails.root, 'spec', 'fixtures', 'theme_views', theme_name)
            end
        end

        def reset_views
            ApplicationMailer.class_eval do
                 self.view_paths = @previous_view_paths
            end
        end

        def create_multipart_method(method_name)
            ApplicationMailer.send(:define_method, method_name) do
                attachment :content_type => 'message/rfc822',
                           :body => 'xxx',
                           :filename => "original.eml",
                           :transfer_encoding => '7bit',
                           :content_disposition => 'inline'
            end
        end

        before do
            set_base_views
            add_mail_methods(['simple', 'theme_only', 'core_only', 'neither'])
        end

        describe 'when a plugin prepends its mail templates to the view paths' do

            it 'should render a theme template in preference to a core template' do
                prepend_theme_views('theme_one')
                @mail = ApplicationMailer.create_simple()
                @mail.body.should match('Theme simple')
            end

            it 'should render the template provided by the theme if no template is available in core' do
                prepend_theme_views('theme_one')
                @mail = ApplicationMailer.create_theme_only()
                @mail.body.should match('Theme only')
            end

            it 'should render the template provided by core if there is no theme template' do
                prepend_theme_views('theme_one')
                @mail = ApplicationMailer.create_core_only()
                @mail.body.should match('Core only')
            end

            it 'should raise an error if the template is in neither core nor theme' do
                prepend_theme_views('theme_one')
                lambda{ ApplicationMailer.create_neither() }.should raise_error('Missing template application_mailer/neither.erb in view path spec/fixtures/theme_views/theme_one:spec/fixtures/theme_views/core')
            end

            it 'should render a multipart email using a theme template' do
                prepend_theme_views('theme_one')
                create_multipart_method('multipart_theme_only')
                @mail = ApplicationMailer.create_multipart_theme_only()
                @mail.parts.size.should == 2
                message_part = @mail.parts[0].to_s
                message_part.should match("Theme multipart")
            end

            it 'should render a multipart email using a core template' do
                prepend_theme_views('theme_one')
                create_multipart_method('multipart_core_only')
                @mail = ApplicationMailer.create_multipart_core_only()
                @mail.parts.size.should == 2
                message_part = @mail.parts[0].to_s
                message_part.should match("Core multipart")
            end

        end

        describe 'when a plugin appends its mail templates to the view paths' do

            it 'should render a core template in preference to a theme template' do
                append_theme_views('theme_one')
                @mail = ApplicationMailer.create_simple()
                @mail.body.should match('Core simple')
            end

            it 'should render the template provided by the theme if no template is available in core' do
                append_theme_views('theme_one')
                @mail = ApplicationMailer.create_theme_only()
                @mail.body.should match('Theme only')
            end

            it 'should render the template provided by core if there is no theme template' do
                append_theme_views('theme_one')
                @mail = ApplicationMailer.create_core_only()
                @mail.body.should match('Core only')
            end

            it 'should raise an error if the template is in neither core nor theme' do
                append_theme_views('theme_one')
                lambda{ ApplicationMailer.create_neither() }.should raise_error('Missing template application_mailer/neither.erb in view path spec/fixtures/theme_views/core:spec/fixtures/theme_views/theme_one')
            end

            it 'should render a multipart email using a core template' do
                append_theme_views('theme_one')
                create_multipart_method('multipart_core_only')
                @mail = ApplicationMailer.create_multipart_core_only()
                @mail.parts.size.should == 2
                message_part = @mail.parts[0].to_s
                message_part.should match("Core multipart")
            end

            it 'should render a multipart email using a theme template' do
                append_theme_views('theme_one')
                create_multipart_method('multipart_theme_only')
                @mail = ApplicationMailer.create_multipart_theme_only()
                @mail.parts.size.should == 2
                message_part = @mail.parts[0].to_s
                message_part.should match("Theme multipart")
            end

        end

        after do
            reset_views
            remove_mail_methods(['simple', 'theme_only', 'core_only', 'neither', 'multipart'])
        end
    end

end



