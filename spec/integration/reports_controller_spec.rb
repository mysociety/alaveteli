require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe ReportsController do

  describe 'reporting a comment' do

    let(:request) { FactoryBot.create(:info_request) }
    let(:comment) { FactoryBot.create(:comment, :info_request => request) }
    let(:user) { FactoryBot.create(:user) }

    describe 'when not logged in' do

      it "should redirect to the login page" do
        visit new_request_report_path(:request_id => request.url_title,
                                      :comment_id => comment.id)

        expect(page).to have_content "create an account or sign in"
      end

      it "should not lose the comment_id post login" do
        visit new_request_report_path(:request_id => request.url_title,
                                      :comment_id => comment.id)

        fill_in :user_signin_email, :with => user.email
        fill_in :user_signin_password, :with => "jonespassword"
        click_button "Sign in"

        expect(page).to have_content "Report annotation on request"
      end

    end
  end
end
