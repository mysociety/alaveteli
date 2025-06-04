require 'spec_helper'

RSpec.describe Users::MessagesController do
  render_views

  let(:sender) { FactoryBot.create(:user, name: 'Bob Smith') }
  let(:recipient) { FactoryBot.create(:user) }

  before { sign_in sender }

  after { ActionMailer::Base.deliveries.clear }

  describe 'GET contact' do
    context 'when not signed in' do
      it 'redirects to signin page' do
        sign_in nil
        get :contact, params: { url_name: recipient.url_name }
        expect(response).
          to redirect_to(signin_path(token: get_last_post_redirect.token))
      end
    end

    it 'shows the contact form' do
      get :contact, params: { url_name: recipient.url_name }
      expect(response).to render_template('contact')
    end

    it 'raises an error if the recipient user is not found' do
      expect {
        get :contact, params: { url_name: 'not-known-at-this-address' }
      }.to raise_error ActiveRecord::RecordNotFound
    end

    context 'when the recipient has opted out' do
      before { recipient.update!(receive_user_messages: false) }

      it 'prevents user messages' do
        get :contact, params: { url_name: recipient.url_name }
        expect(response).to render_template('users/messages/opted_out')
      end
    end

    context 'when user-to-user messaging is disabled', features: { user_to_user_messaging: false } do
      it 'prevents user messages' do
        get :contact, params: { url_name: recipient.url_name }
        expect(response).to render_template('users/messages/disabled')
      end
    end

    it 'prevents messages from users who have reached their rate limit' do
      allow_any_instance_of(User).
        to receive(:exceeded_limit?).with(:user_messages).and_return(true)

      get :contact, params: { url_name: recipient.url_name }

      expect(response).to render_template('users/messages/rate_limited')
    end
  end

  describe 'POST contact' do
    it 'shows an error if not given a subject line' do
      post :contact, params: {
                       url_name: recipient.url_name,
                       contact: {
                         subject: '',
                         message: 'Gah'
                       },
                       submitted_contact_form: 1
                     }
      expect(response).to render_template('contact')
    end

    context 'when the recipient has opted out' do
      before { recipient.update!(receive_user_messages: false) }

      it 'prevents the submission' do
        post :contact, params: {
          url_name: recipient.url_name,
          contact: {
            subject: 'Hi',
            message: 'Gah'
          },
          submitted_contact_form: 1
        }

        expect(ActionMailer::Base.deliveries).to be_empty
        expect(response).to render_template('users/messages/opted_out')
      end
    end

    context 'when user-to-user messaging is disabled', features: { user_to_user_messaging: false } do
      it 'prevents the submission' do
        post :contact, params: {
          url_name: recipient.url_name,
          contact: {
            subject: 'Hi',
            message: 'Gah'
          },
          submitted_contact_form: 1
        }

        expect(ActionMailer::Base.deliveries).to be_empty
        expect(response).to render_template('users/messages/disabled')
      end
    end

    it 'prevents messages from users who have reached their rate limit' do
      allow_any_instance_of(User).
        to receive(:exceeded_limit?).with(:user_messages).and_return(true)

      post :contact, params: {
        url_name: recipient.url_name,
        contact: {
          subject: 'Foo',
          message: 'Bar'
        },
        submitted_contact_form: 1
      }

      expect(response).to render_template('users/messages/rate_limited')
    end

    context 'the site is configured to require a captcha' do
      before do
        allow(AlaveteliConfiguration).
          to receive(:user_contact_form_recaptcha).and_return(true)
        allow(controller).to receive(:verify_recaptcha).and_return(false)
      end

      it 'does not send the message without the recaptcha being completed' do
         post :contact, params: {
                          url_name: recipient.url_name,
                          contact: {
                            subject: 'Have some spam',
                            message: 'Spam, spam, spam'
                          },
                          submitted_contact_form: 1
                        }

         deliveries = ActionMailer::Base.deliveries
         expect(deliveries.size).to eq(0)
         deliveries.clear
       end
    end

    it 'sends the message' do
      post :contact, params: {
                       url_name: recipient.url_name,
                       contact: {
                         subject: 'Dearest you',
                         message: 'Just a test!'
                       },
                       submitted_contact_form: 1
                     }
      expect(response).to redirect_to(user_url(recipient))

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.body).
        to include("Bob Smith has used #{site_name} " \
                   "to send you the message below")
      expect(mail.body).to include('Just a test!')
      # TODO: fix some nastiness with quoting name_and_email
      # mail.to_addrs.first.to_s.should == recipient.name_and_email
      expect(mail.header['Reply-To'].to_s).to match(sender.email)
    end

    it 'records the message' do
      post :contact, params: {
        url_name: recipient.url_name,
        contact: {
          subject: 'Dearest you',
          message: 'Just a test!'
        },
        submitted_contact_form: 1
      }

      expect(UserMessage.last.user).to eq(sender)
    end
  end

  describe 'when sending a message that looks like spam' do
    let(:sender) { FactoryBot.create(:user, confirmed_not_spam: false) }
    let(:recipient) { FactoryBot.create(:user) }
    let(:spam_content) { '[HD] Watch Jason Bourne Online free MOVIE Full-HD' }

    context 'when block_spam_user_messages? is true' do
      before do
        allow(@controller).
          to receive(:block_spam_user_messages?).and_return(true)
        sign_in(sender)
      end

      it 'sends an exception notification' do
        post :contact, params: {
          url_name: recipient.url_name,
          contact: {
            subject: 'Dearest you',
            message: spam_content
          },
          submitted_contact_form: 1
        }

        expect(ActionMailer::Base.deliveries.first.subject).
          to match(/spam user message from user #{ sender.id }/)
      end

      it 'shows an error message' do
        post :contact, params: {
          url_name: recipient.url_name,
          contact: {
            subject: 'Dearest you',
            message: spam_content
          },
          submitted_contact_form: 1
        }

        msg = "Sorry, we're currently unable to send your message. " \
              "Please try again later."

        expect(flash[:error]).to eq(msg)
      end

      it 'renders the compose interface' do
        post :contact, params: {
          url_name: recipient.url_name,
          contact: {
            subject: 'Dearest you',
            message: spam_content
          },
          submitted_contact_form: 1
        }

        expect(response).to render_template('contact')
      end

      it 'allows the message if the sender is confirmed not spam' do
        sender.update!(confirmed_not_spam: true)

        post :contact, params: {
          url_name: recipient.url_name,
          contact: {
            subject: 'Dearest you',
            message: spam_content
          },
          submitted_contact_form: 1
        }

        expect(response).to redirect_to(user_url(recipient))
        expect(ActionMailer::Base.deliveries.first.subject).to match(/Dearest/)
      end
    end

    context 'when block_spam_user_messages? is false' do
      before do
        allow(@controller).
          to receive(:block_spam_user_messages?).and_return(false)
        sign_in(sender)
      end

      it 'sends an exception notification' do
        post :contact, params: {
          url_name: recipient.url_name,
          contact: {
            subject: 'Dearest you',
            message: spam_content
          },
          submitted_contact_form: 1
        }

        expect(ActionMailer::Base.deliveries.first.subject).
          to match(/spam user message from user #{ sender.id }/)
      end

      it 'sends the message' do
        post :contact, params: {
          url_name: recipient.url_name,
          contact: {
            subject: 'Dearest you',
            message: spam_content
          },
          submitted_contact_form: 1
        }

        expect(response).to redirect_to(user_url(recipient))
        expect(ActionMailer::Base.deliveries.last.subject).to match(/Dearest/)
      end
    end
  end
end
