# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'integration/alaveteli_dsl'
require 'support/shared_examples_for_viewing_requests'

describe "viewing requests in alaveteli_pro" do
  let(:pro_user) { FactoryBot.create(:pro_user) }
  let(:info_request) { FactoryBot.create(:info_request, user: pro_user) }
  let!(:pro_user_session) { login(pro_user) }

  context 'a pro user viewing one of their own requests' do

    it 'allows the user to view the request' do
      using_pro_session(pro_user_session) do
        browse_pro_request(info_request.url_title)
        expect(page).to have_content(info_request.title)
      end
    end

    include_examples 'allows annotations'

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

      context 'the user does not have a pro account' do

        before do
          pro_user.remove_role(:pro)
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
        FactoryBot.create(:embargo, info_request: info_request)
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

      include_examples 'allows the embargo to be lifted'

      context 'the user does not have pro status' do

        before do
          pro_user.remove_role(:pro)
        end

        include_examples 'prevents setting an embargo'

      end

      include_examples 'allows followups'

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
              to have_content("This request is private until " \
                              "#{old_publish_at.strftime('%-d %B %Y')}")
            select "3 Months", from: "Keep private for a further:"
            within ".update-embargo" do
              click_button("Update")
            end
            expected = old_publish_at + AlaveteliPro::Embargo::THREE_MONTHS
            expect(embargo.reload.publish_at).to eq(expected)
            expect(page).
              to have_content("This request is private until " \
                              "#{expected.strftime('%-d %B %Y')}")
          end

        end

        context 'the user does not have pro status' do

          before do
            pro_user.remove_role(:pro)
          end

          it 'does not show the option to extend the embargo' do
            using_pro_session(pro_user_session) do
              browse_pro_request(info_request.url_title)
              expect(page).
                to have_content("This request is private until " \
                                "#{embargo.publish_at.strftime('%-d %B %Y')}")
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
              to have_content("This request is private until " \
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

        context 'the user does not have pro status' do

          before do
            pro_user.remove_role(:pro)
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
        it_behaves_like 'a request with response'
      end

    end

  end

end
