# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WidgetsController do

    include LinkToHelper

    describe "#show" do

        before do
            @info_request = FactoryGirl.create(:info_request)
        end

        it 'should render the widget template' do
            get :show, :request_id => @info_request.id
            expect(response).to render_template('show')
        end

        it 'should find the info request' do
            get :show, :request_id => @info_request.id
            assigns[:info_request].should == @info_request
        end

        it 'should create a track thing for the request' do
            get :show, :request_id => @info_request.id
            assigns[:track_thing].info_request.should == @info_request
        end

        it 'should assign the request status' do
            get :show, :request_id => @info_request.id
            assigns[:status].should == @info_request.calculate_status
        end

        context 'for a non-logged-in user' do

            context 'if no widget-vote cookie is set' do

                it 'should set a widget-vote cookie' do
                    cookies[:widget_vote].should be_nil
                    get :show, :request_id => @info_request.id
                    cookies[:widget_vote].should_not be_nil
                end

            end

        end


    end

    describe "#new" do

        before do
            @info_request = FactoryGirl.create(:info_request)
        end

        it 'should render the create widget template' do
            get :new, :request_id => @info_request.id
            expect(response).to render_template('new')
        end

        it 'should find the info request' do
            get :new, :request_id => @info_request.id
            assigns[:info_request].should == @info_request
        end

    end

    describe :update do

        before do
            @info_request = FactoryGirl.create(:info_request)
        end

        it 'should find the info request' do
            get :update, :request_id => @info_request.id
            assigns[:info_request].should == @info_request
        end

        it 'should redirect to the track path for the info request' do
            get :update, :request_id => @info_request.id
            track_thing = TrackThing.create_track_for_request(@info_request)
            expect(response).to redirect_to(do_track_path(track_thing))
        end

        context 'when there is no logged-in user and a widget vote cookie' do

            before do
                @cookie_value = 'x' * 20
            end

            it 'should create a widget vote if none exists for the info request and cookie' do
                @info_request.widget_votes.where(:cookie => @cookie_value).size.should == 0
                request.cookies['widget_vote'] = @cookie_value
                get :update, :request_id => @info_request.id
                @info_request.widget_votes.where(:cookie => @cookie_value).size.should == 1
            end

            it 'should not create a widget vote if one exists for the info request and cookie' do
                @info_request.widget_votes.create(:cookie => @cookie_value)
                request.cookies['widget_vote'] = @cookie_value
                get :update, :request_id => @info_request.id
                @info_request.widget_votes.where(:cookie => @cookie_value).size.should == 1
            end

        end

    end

end

