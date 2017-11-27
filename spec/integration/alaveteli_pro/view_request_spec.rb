# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../alaveteli_dsl')
require 'stripe_mock'

describe "viewing requests in alaveteli_pro" do
  let(:stripe_helper) { StripeMock.create_test_helper }

  before do
    StripeMock.start
    AlaveteliFeatures.backend.enable(:pro_pricing)
    stripe_helper.create_plan(id: 'pro', amount: 1000)
  end

  after do
    StripeMock.stop
    AlaveteliFeatures.backend.disable(:pro_pricing)
  end

  let(:pro_user) do
    user = FactoryGirl.create(:pro_user)
    customer = Stripe::Customer.create({
      email: user.email,
      source: stripe_helper.generate_card_token,
    })
    user.pro_account.update!(stripe_customer_id: customer.id)
    Stripe::Subscription.create(customer: customer, plan: 'pro')
    user
  end

  let(:info_request) { FactoryGirl.create(:info_request, user: pro_user) }
  let!(:pro_user_session) { login(pro_user) }

  context 'a pro user viewing one of their own requests' do

    it 'allows the user to view the request' do
      using_pro_session(pro_user_session) do
        browse_pro_request(info_request.url_title)
        expect(page).to have_content(info_request.title)
      end
    end

    it 'allows the user to add an annotation' do
      using_pro_session(pro_user_session) do
        browse_pro_request(info_request.url_title)
        first(:link, 'Add an annotation').click
        expect(page).
          to have_content "Add an annotation to “#{info_request.title}”"
        fill_in("comment_body", with: "Testing annotations")
        click_button("Preview your annotation")
        click_button("Post annotation")
        expect(page).to have_content("#{pro_user.name} left an annotation")
        expect(page).to have_content("Testing annotations")
      end
    end

    context 'the request is not embargoed' do

      it 'shows the privacy sidebar' do
        using_pro_session(pro_user_session) do
          browse_pro_request(info_request.url_title)
          expect(page).to have_css("h2", text: "Privacy")
        end
      end

      it 'does not show an embargo end date' do
        using_pro_session(pro_user_session) do
          browse_pro_request(info_request.url_title)
          expect(page).not_to have_content "Private until"
        end
      end

      it 'does not prompt the user to publish their request' do
        using_pro_session(pro_user_session) do
          browse_pro_request(info_request.url_title)
          expect(page).not_to have_content "Publish request"
        end
      end

      it 'shows the option to add an embargo' do
        using_pro_session(pro_user_session) do
          browse_pro_request(info_request.url_title)
          expect(page).to have_content "Keep private for"
        end
      end

      context 'the user does not have an active subscription' do

        before do
          pro_user.pro_account.update!(stripe_customer_id: nil)
        end

        it 'does not show the privacy sidebar' do
          using_pro_session(pro_user_session) do
            browse_pro_request(info_request.url_title)
            expect(page).not_to have_css("h2", text: "Privacy")
          end
        end

        it 'does not show the option to add an embargo' do
          using_pro_session(pro_user_session) do
            browse_pro_request(info_request.url_title)
            expect(page).not_to have_content "Keep private for"
          end
        end

      end

    end

    context 'the request is embargoed' do

      let!(:embargo) do
        FactoryGirl.create(:embargo, info_request: info_request)
      end

      it 'shows the privacy sidebar' do
        using_pro_session(pro_user_session) do
          browse_pro_request(info_request.url_title)
          expect(page).to have_css("h2", text: "Privacy")
        end
      end

      it 'does not show the option to add an embargo' do
        using_pro_session(pro_user_session) do
          browse_pro_request(info_request.url_title)
          expect(page).not_to have_content "Keep private for"
        end
      end

      it 'does not allow the user to link to individual messages' do
        using_pro_session(pro_user_session) do
          browse_pro_request(info_request.url_title)
          expect(page).not_to have_content("Link to this")
        end
      end

      it 'allows the user to publish the request' do
        using_pro_session(pro_user_session) do
          browse_pro_request(info_request.url_title)
          old_publish_at = embargo.publish_at.strftime('%-d %B %Y')
          expect(page).to have_content("This request is private on " \
                                       "Alaveteli until #{old_publish_at}")
          click_button("Publish request")
          expect(info_request.reload.embargo).to be nil
          expect(page).to have_content("Your request is now public!")
        end
      end

      context 'the user does not have an active subscription' do

        before do
          pro_user.pro_account.update!(stripe_customer_id: nil)
        end

        it 'allows the user to publish a request' do
          using_pro_session(pro_user_session) do
            browse_pro_request(info_request.url_title)
            old_publish_at = embargo.publish_at.strftime('%-d %B %Y')
            expect(page).to have_content("This request is private on " \
                                         "Alaveteli until #{old_publish_at}")
            click_button("Publish request")
            expect(info_request.reload.embargo).to be nil
            expect(page).to have_content("Your request is now public!")
          end
        end

      end

      it 'allows the user to send a follow up' do
        using_pro_session(pro_user_session) do
          browse_pro_request(info_request.url_title)
          first(:link, 'Send a followup').click
          expect(page).to have_content "Send a follow up message to the " \
                                       "main FOI contact at " \
                                       "#{info_request.public_body.name}"
          fill_in("outgoing_message_body", with: "Testing follow ups")
          choose("Anything else, such as clarifying, prompting, thanking")
          click_button("Preview your message")
          click_button("Send message")
          expect(page).to have_content("Testing follow ups")
        end
      end

      context 'the embargo is expiring soon' do

        before do
          embargo.update_attribute(:publish_at, embargo.publish_at - 88.days)
          info_request.reload
        end

        it 'allows the user to extend an embargo' do
          using_pro_session(pro_user_session) do
            browse_pro_request(info_request.url_title)
            old_publish_at = embargo.publish_at
            expect(page).
              to have_content("This request is private on " \
                              "Alaveteli until " \
                              "#{old_publish_at.strftime('%d %B %Y')}")
            select "3 Months", from: "Keep private for a further:"
            within ".update-embargo" do
              click_button("Update")
            end
            expected = old_publish_at + AlaveteliPro::Embargo::THREE_MONTHS
            expect(embargo.reload.publish_at).to eq(expected)
            expect(page).
              to have_content("This request is private on Alaveteli until " \
                              "#{expected.strftime('%d %B %Y')}")
          end

        end

        context 'the user does not have an active subscription' do

          before do
            pro_user.pro_account.update!(stripe_customer_id: nil)
          end

          it 'does not show the option to extend the embargo' do
            using_pro_session(pro_user_session) do
              browse_pro_request(info_request.url_title)
              expect(page).
                to have_content("This request is private on Alaveteli until " \
                                "#{embargo.publish_at.strftime('%d %B %Y')}")
              expect(page).not_to have_content('Keep private for a further:')
            end
          end

        end

      end

      context 'the embargo is not expiring soon' do

        it 'does not show the user the extend embargo section' do
          using_pro_session(pro_user_session) do
            browse_pro_request(info_request.url_title)
            expect(page).not_to have_content('Keep private for a further:')
            expect(page).
              to have_content("This request is private on Alaveteli until " \
                              "#{embargo.publish_at.strftime('%-d %B %Y')}")
          end
        end

        it 'displays a message to say when the embargo can be extended' do
          using_pro_session(pro_user_session) do
            expiring_notification = info_request.
                                      embargo.calculate_expiring_notification_at
            browse_pro_request(info_request.url_title)
            expect(page).
              to have_content("You will be able to extend this privacy " \
                              "period from " \
                              "#{expiring_notification.strftime('%-d %B %Y')}")
          end
        end

        context 'the user does not have an active subscription' do

          before do
            pro_user.pro_account.update!(stripe_customer_id: nil)
          end

          it 'does not display a message to say when the embargo can be extended' do
            using_pro_session(pro_user_session) do
              expiring_notification = info_request.
                                        embargo.
                                          calculate_expiring_notification_at.
                                            strftime('%-d %B %Y')
              browse_pro_request(info_request.url_title)
              expect(page).
                to_not have_content("You will be able to extend this privacy " \
                                    "period from #{expiring_notification}")
            end

          end

        end

      end

      context 'the request has received a response' do

        before do
          incoming_message = FactoryGirl.create(:plain_incoming_message,
                                                :info_request => info_request)
          info_request.log_event("response",
                                 {:incoming_message_id => incoming_message.id})
        end

        it 'allows the user to write a reply' do
          using_pro_session(pro_user_session) do
            browse_pro_request(info_request.url_title)
            first(:link, "Write a reply").click
            expect(page).to have_content "Send a reply to"
            fill_in("outgoing_message_body", with: "Testing replies")
            choose("Anything else, such as clarifying, prompting, thanking")
            click_button("Preview your message")
            click_button("Send message")
            expect(page).to have_content("Testing replies")
          end
        end

        it 'allows the user to download the entire request' do
          using_pro_session(pro_user_session) do
            browse_pro_request(info_request.url_title)
            first(:link, "Download a zip file of all correspondence").click
            expected = /attachment; filename="example_title_.*\.zip"/
            expect(page.response_headers["Content-Disposition"]).
              to match(expected)
          end
        end

        it 'allows the user to request an internal review' do
          using_pro_session(pro_user_session) do
            browse_pro_request(info_request.url_title)
            first(:link, "Request an internal review").click
            expect(page).to have_content "Request an internal review from " \
                                         "the main FOI contact at " \
                                         "#{info_request.public_body.name}"
            fill_in("outgoing_message_body", with: "Testing internal reviews")
            click_button("Preview your message")
            click_button("Send message")
            expect(page).to have_content("Testing internal reviews")
          end
        end

        it 'allows the user to update the request status' do
          using_pro_session(pro_user_session) do
            browse_pro_request(info_request.url_title)
            expect(page).to have_content("Status")
            check 'Change status'
            # The current status shouldn't be checked, so that you can set it
            # again if you need too, e.g. to reset the awaiting response status
            expect(find_field("Awaiting response")).not_to be_checked
            choose("Partially successful")
            within ".update-status" do
              click_button("Update")
            end
            expect(info_request.reload.described_state).
              to eq ("partially_successful")
            expect(page).to have_content("Your request has been updated!")
            # The form should still be there to allow us to go back if we
            # updated by mistake
            expect(page).to have_content("Status")
            check 'Change status'
          end
        end

      end

    end

  end

end
