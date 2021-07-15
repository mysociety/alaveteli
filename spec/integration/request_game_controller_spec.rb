require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe RequestGameController do

  describe "classifying a request" do

    let(:user) { FactoryBot.create(:user) }

    it 'displays a thank you message on completion' do
      request = FactoryBot.create(:old_unclassified_request,
                                  :title => "Awkward > Title")
      using_session(login(user)) do
        visit categorise_play_path
        click_link(request.title)
        choose("rejected1")
        within "#describe_state_form_1" do
          find_button("Submit status").click
        end

        message = "Thank you for updating the status of the request " \
                  "'#{request.title}'. There are some more requests below " \
                  "for you to classify."

        expect(page).to have_link(request.title, :href => request_path(request))
        expect(page).to have_content(message)
      end
    end

  end

end
