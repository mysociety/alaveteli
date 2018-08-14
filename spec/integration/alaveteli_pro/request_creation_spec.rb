# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../alaveteli_dsl')

describe "creating requests in alaveteli_pro" do
  context "when writing a new request from scratch" do
    let!(:public_body) { FactoryBot.create(:public_body, :name => 'example') }
    let!(:pro_user) { FactoryBot.create(:pro_user) }
    let!(:pro_user_session) { login(pro_user) }

    before do
      update_xapian_index
    end

    it "doesn't show the link to the batch request form to standard users" do
      using_pro_session(pro_user_session) do
        # New request form
        create_pro_request(public_body)
        expect(page).not_to have_content("start a batch request")
      end
    end

    it "shows the link to the batch request form to pro batch users" do
      AlaveteliFeatures.backend.enable_actor(:pro_batch_access, pro_user)

      using_pro_session(pro_user_session) do
        # New request form
        create_pro_request(public_body)
        expect(page).to have_content("start a batch request")
      end
    end

    it "allows us to save a draft" do
      using_pro_session(pro_user_session) do
        # New request form
        create_pro_request(public_body)
        click_button "Save draft"

        # Redirected back to new request form
        drafts = DraftInfoRequest.where(title: "Does the pro request form work?")
        expect(drafts).to exist
        draft = drafts.first
        expect(draft.body).to eq "A very short letter."
        expect(draft.embargo_duration).to eq "3_months"

        embargoed_until = AlaveteliPro::Embargo.three_months_from_now
        expect(page).to have_content("Your draft has been saved!")
        expect(page).to have_content("This request will be private until " \
                                     "#{embargoed_until.strftime('%-d %B %Y')}")

        # The page should pre-fill the form with data from the draft
        expect(page).to have_field("To", with: public_body.name)
        expect(page).to have_field("Subject",
                                   with: "Does the pro request form work?")
        expect(page).to have_field("Your request",
                                   with: "A very short letter.")
        expect(page).to have_select("Privacy", selected: "3 Months")
      end
    end

    it "allows us to preview the request" do
      using_pro_session(pro_user_session) do
        # New request form
        create_pro_request(public_body)
        click_button "Preview and send"

        # Preview page
        drafts = DraftInfoRequest.where(title: "Does the pro request form work?")
        expect(drafts).to exist

        expect(page).to have_content("Preview new FOI request to '#{public_body.name}'")
        # The fact there's a draft should be hidden from the user
        expect(page).not_to have_content("Your draft has been saved!")

        expect(page).to have_content("To #{public_body.name}")
        expect(page).to have_content("Subject Does the pro request form " \
                                     "work?")
        expect(page).to have_content("A very short letter.")
        embargoed_until = AlaveteliPro::Embargo.three_months_from_now
        expect(page).to have_content("This request will be private until " \
                                     "#{embargoed_until.strftime('%-d %B %Y')}")
      end
    end

    it 'does not render HTML on the preview page' do
      public_body.update_attribute(:name, "Test's <sup>html</sup> authority")
      using_pro_session(pro_user_session) do
        visit show_public_body_path(:url_name => public_body.url_name)
        click_link("Make a request to this authority")
        fill_in 'Subject', :with => "HTML test"
        click_button "Preview and send"

        expect(page).to have_content("Dear Test's <sup>html</sup> authority")
      end
    end

    it "allows us to send the request" do
      using_pro_session(pro_user_session) do
        # New request form
        create_pro_request(public_body)
        click_button "Preview and send"

        # Preview page
        click_button "Send request"

        # Request page
        expect(page).to have_selector("h1", text: "Does the pro request form work?")

        drafts = DraftInfoRequest.where(title: "Does the pro request form work?")
        expect(drafts).not_to exist

        info_requests = InfoRequest.where(title: "Does the pro request form work?")
        expect(info_requests).to exist

        info_request = info_requests.first

        embargo = info_request.embargo
        expect(embargo).not_to be_nil
        expect(embargo.publish_at).to eq AlaveteliPro::Embargo.three_months_from_now

        expect(info_request.outgoing_messages.length).to eq 1
        expect(info_request.outgoing_messages.first.body).to eq "A very short letter."

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        mail = deliveries[0]
        expect(mail.body).to match(/A very short letter\./)
        expect(mail.subject).to match(/Freedom of Information request - Does the pro request form work\?/)
        expect(mail.to).to eq([public_body.request_email])
      end
    end

    it "allow us to edit a request after previewing" do
      using_pro_session(pro_user_session) do
        # New request form
        create_pro_request(public_body)
        click_button "Preview and send"

        # Preview page
        click_link "Edit your request"

        # New request form again
        # The page should pre-fill the form with data from the draft
        expect(page).to have_field("To", with: public_body.name)
        expect(page).to have_field("Subject",
                                   with: "Does the pro request form work?")
        expect(page).to have_field("Your request",
                                   with: "A very short letter.")
        expect(page).to have_select("Privacy", selected: "3 Months")

        fill_in "Your request", with: "A very short letter, edited."
        click_button "Save draft"

        # Redirected back to new request form
        drafts = DraftInfoRequest.where(title: "Does the pro request form work?")
        expect(drafts).to exist
        draft = drafts.first
        expect(draft.body).to eq "A very short letter, edited."
        expect(draft.embargo_duration).to eq "3_months"

        expect(page).to have_content("Your draft has been saved!")

        click_button "Preview and send"

        # Preview page again
        expect(page).to have_content("Preview new FOI request to '#{public_body.name}'")
        # The fact there's a draft should be hidden from the user
        expect(page).not_to have_content("Your draft has been saved!")

        expect(page).to have_content("To #{public_body.name}")
        expect(page).to have_content("Subject Does the pro request form " \
                                     "work?")
        expect(page).to have_content("A very short letter, edited.")
        embargoed_until = AlaveteliPro::Embargo.three_months_from_now
        expect(page).to have_content("This request will be private until " \
                                     "#{embargoed_until.strftime('%-d %B %Y')}")
      end
    end

    it "shows errors if we leave fields blank" do
      using_pro_session(pro_user_session) do
        # New request form
        visit new_alaveteli_pro_info_request_path
        expect(page).to have_content "Make a request"
        click_button "Preview and send"

        # New request form with errors
        expect(page).to have_content "Please enter a summary of your " \
                                     "request"
        expect(page).to have_content "Please enter your letter requesting " \
                                     "information"
        expect(page).to have_content "Please select an authority"
      end
    end

    it "fills out the body with a template message" do
      using_pro_session(pro_user_session) do
        # New request form
        visit new_alaveteli_pro_info_request_path
        expect(page).to have_content <<-EOF
Dear [Authority name],



Yours faithfully,

#{pro_user.name}
        EOF
      end
    end

    it "saves the draft even if we leave fields blank" do
      using_pro_session(pro_user_session) do
        # New request form
        visit new_alaveteli_pro_info_request_path
        expect(page).to have_content "Make a request"
        fill_in "Your request", with: "A very short letter."
        click_button "Save draft"

        # New request form with errors
        expect(page).not_to have_content "Please enter a summary of your " \
                                         "request"
        expect(page).not_to have_content "Please select an authority"
        expect(page).not_to have_content 'Please sign at the bottom with ' \
                                         'your name, or alter the "Yours ' \
                                         'faithfully," signature'
      end
    end

    it "redirects to the pro page if the user starts the normal process" do
      # Make a request in the normal way
      with_feature_enabled(:alaveteli_pro) do
        create_request(public_body)

        # Sign in page
        within '#signin_form' do
          fill_in "Your e-mail:", with: pro_user.email
          fill_in "Password:", with: "jonespassword"
          click_button "Sign in"
        end

        # The post redirect process should save a Draft
        expect(DraftInfoRequest.count).to eq 1

        # Pro request form
        expect(page).to have_content("Thanks for logging in. We've saved your " \
                                    "request as a draft, in case you wanted to " \
                                    "add an embargo before sending it. You can " \
                                    "set that (or just send it straight away) " \
                                    "using the form below.")
        expect(page).to have_field("To", with: public_body.name)
        expect(page).to have_field("Subject",
                                   with: "Why is your quango called Geraldine?")
        expect(page).to have_field("Your request",
                                   with: "This is a silly letter. It is too short to be interesting.")

        select "3 Months", from: "Privacy"
        click_button "Preview and send"

        # Preview page
        click_button "Send request"

        # Request page
        expect(page).to have_selector("h1", text: "Why is your quango called Geraldine?")
      end
    end
  end
end
