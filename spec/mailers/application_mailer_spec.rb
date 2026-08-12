require 'spec_helper'

RSpec.describe ApplicationMailer do
  describe '#mail_user' do
    let(:info_request) { FactoryBot.create(:info_request, user: user) }

    let!(:incoming_message) do
      FactoryBot.create(:incoming_message, info_request: info_request)
    end

    def deliver
      RequestMailer.new_response(info_request, incoming_message).deliver_now
      ActionMailer::Base.deliveries.last
    end

    context 'when the recipient does not use the default locale' do
      let(:user) { FactoryBot.create(:user, locale: 'es') }

      it 'renders the subject and body in the recipient locale' do
        mail = deliver
        expect(mail.subject).to start_with('Nueva respuesta')
        expect(mail.body).
          to include('Para ver la respuesta, usa el siguiente enlace.')
      end
    end

    context 'when another locale is in use as the mail is sent' do
      let(:user) { FactoryBot.create(:user, locale: 'en') }

      it 'ignores it and uses the recipient locale' do
        mail = AlaveteliLocalization.with_locale('es') { deliver }
        expect(mail.subject).to start_with('New response')
        expect(mail.body).
          to include('To view the response, click on the link below.')
      end
    end
  end

  context 'when using plugins' do
    def set_base_views
      ApplicationMailer.class_eval do
        @previous_view_paths = view_paths.dup
        self.view_paths = [File.join(Rails.root, 'spec', 'fixtures', 'theme_views', 'core')]
      end
    end

    def add_mail_methods(method_names)
      @previous_layout = ApplicationMailer._layout.dup
      ApplicationMailer.send(:layout, nil)
      method_names.each { |method_name| ApplicationMailer.send(:define_method, method_name) { mail } }
    end

    def remove_mail_methods(method_names)
      ApplicationMailer.send(:layout, @previous_layout)
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
        mail(content_type: 'multipart/mixed')
      end
    end

    before do
      set_base_views
      add_mail_methods(%w[simple theme_only core_only neither])
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

      it 'should raise a missing template error if the template is in
          neither core nor theme' do
        prepend_theme_views('theme_one')
        @mail = ApplicationMailer.neither
        expect { @mail.body }.to raise_error(ActionView::MissingTemplate)
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

      it 'should raise a missing template error if the template is in
          neither core nor theme' do
        append_theme_views('theme_one')
        @mail = ApplicationMailer.neither
        expect { @mail.body }.to raise_error(ActionView::MissingTemplate)
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
      remove_mail_methods(%w[simple theme_only core_only neither multipart])
    end
  end
end
