# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe 'when displaying actions that can be taken with regard to a request' do
    let(:info_request) { FactoryGirl.create(:info_request) }
    let(:track_thing) do
      FactoryGirl.create(:request_update_track, info_request: info_request)
    end

    before do
      assign :info_request, info_request
      assign :track_thing, track_thing
    end

    describe 'if the request is old and unclassified' do
      before do
        assign :old_unclassified, true
      end

      it 'should not display a link for the request owner to update the status of the request' do
        render :partial => 'request/after_actions'
        expect(response.body).to have_css('ul.owner_actions') do |div|
          expect(div).not_to have_css('a', :text => 'Update the status of this request')
        end
      end

      it 'should display a link for anyone to update the status of the request' do
        render :partial => 'request/after_actions'
        expect(response.body).to have_css('ul.anyone_actions') do |div|
          expect(div).to have_css('a', :text => 'Update the status of this request')
        end
      end
    end

    describe 'if the request is not old and unclassified' do
      before do
        assign :old_unclassified, false
      end

      it 'should display a link for the request owner to update the status of the request' do
        render :partial => 'request/after_actions'
        expect(response.body).to have_css('ul.owner_actions') do |div|
          expect(div).to have_css('a', :text => 'Update the status of this request')
        end
      end

      it 'should not display a link for anyone to update the status of the request' do
        render :partial => 'request/after_actions'
        expect(response.body).to have_css('ul.anyone_actions') do |div|
          expect(div).not_to have_css('a', :text => 'Update the status of this request')
        end
      end
    end

    it 'should display a link for the request owner to request a review' do
      render :partial => 'request/after_actions'
      expect(response.body).to have_css('ul.owner_actions') do |div|
        expect(div).to have_css('a', :text => 'Request an internal review')
      end
    end


    it 'should display the link to download the entire request' do
      render :partial => 'request/after_actions'
      expect(response.body).to have_css('ul.anyone_actions') do |div|
        expect(div).to have_css('a', :text => 'Download a zip file of all correspondence')
      end
    end

    it "should display a link to annotate the request" do
      with_feature_enabled(:annotations) do
        render :partial => 'request/after_actions'
        expect(response.body).to have_css('ul.anyone_actions') do |div|
            expect(div).to have_css('a', :text => 'Add an annotation (to help the requester or others)')
        end
      end
    end

    it "should not display a link to annotate the request if comments are disabled on it" do
      with_feature_enabled(:annotations) do
        info_request.comments_allowed = false
        render :partial => 'request/after_actions'
        expect(response.body).to have_css('ul.anyone_actions') do |div|
            expect(div).not_to have_css('a', :text => 'Add an annotation (to help the requester or others)')
        end
      end
    end

    it "should not display a link to annotate the request if comments are disabled globally" do
      with_feature_disabled(:annotations) do
        render :partial => 'request/after_actions'
        expect(response.body).to have_css('ul.anyone_actions') do |div|
          expect(div).not_to have_css('a', :text => 'Add an annotation (to help the requester or others)')
        end
      end
    end
end
