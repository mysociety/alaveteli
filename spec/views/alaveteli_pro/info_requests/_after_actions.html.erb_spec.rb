# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', '..', 'spec_helper'), __FILE__)

describe 'when displaying actions that can be taken with regard to a pro request' do
  let(:info_request) { FactoryGirl.create(:info_request) }
  let(:pro_user) { info_request.pro_user }
  let(:admin_user) { FactoryGirl.create("admin_user") }

  before do
    assign :info_request, info_request
  end

  def render_view
    render :partial => 'alaveteli_pro/info_requests/after_actions'
  end

  it 'should display a link to request a review' do
    render_view
    within('.action-menu__menu__submenu') do
      expect(rendered).to have_css('a', :text => 'Request an internal review')
    end
  end

  it 'should display the link to download the entire request' do
    render_view
    within('.action-menu__menu__submenu') do
      expect(rendered).to have_css('a', :text => 'Download a zip file of all correspondence')
    end
  end

  it "should display a link to annotate the request" do
    with_feature_enabled(:annotations) do
      render_view
      within('.action-menu__menu__submenu') do
        expect(rendered).to have_css('a', :text => 'Add an annotation (to help the requester or others)')
      end
    end
  end

  it "should not display a link to annotate the request if comments are disabled on it" do
    with_feature_enabled(:annotations) do
      info_request.comments_allowed = false
      render_view
      within('.action-menu__menu__submenu') do
        expect(rendered).not_to have_css('a', :text => 'Add an annotation')
      end
    end
  end

  it "should not display a link to annotate the request if comments are disabled globally" do
    with_feature_disabled(:annotations) do
      render_view
      within('.action-menu__menu__submenu') do
        expect(rendered).not_to have_css('a', :text => 'Add an annotation')
      end
    end
  end

  context "when there is a response" do
    let(:info_request) { FactoryGirl.create(:info_request_with_incoming) }

    before do
      assign :info_request, info_request
      assign :last_response, info_request.get_last_public_response
    end

    it "should display a link to reply" do
      render_view
      within('.action-menu__menu__submenu') do
        expect(rendered).to have_css('a', :text => 'Write a reply')
      end
    end
  end

  context "when there is no response" do
    before do
      assign :last_response, nil
    end

    it "should display a link to send a follow up" do
      render_view
      within('.action-menu__menu__submenu') do
        expect(rendered).to have_css('a', :text => 'Send a follow up')
      end
    end
  end
end
