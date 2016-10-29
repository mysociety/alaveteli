# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminCommentController do

  describe 'GET index' do

    it 'sets the title' do
      get :index
      expect(assigns[:title]).to eq('Listing comments')
    end

    it 'collects comments by creation date' do
      Comment.destroy_all
      time_travel_to(1.month.ago)
      comment_1 = FactoryGirl.create(:comment)
      back_to_the_present
      comment_2 = FactoryGirl.create(:comment)
      get :index
      expect(assigns[:comments]).to eq([comment_2, comment_1])
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template('index')
    end

    it 'responds successfully' do
      get :index
      expect(response).to be_success
    end

  end

  describe 'GET edit' do

    before do
      @comment = FactoryGirl.create(:comment)
      get :edit, :id => @comment.id
    end

    it 'renders the edit template' do
      expect(response).to render_template('edit')
    end

    it 'gets the comment' do
      expect(assigns[:comment]).to eq(@comment)
    end

  end

  describe 'PUT update' do

    context 'on valid data submission' do

      before do
        @comment = FactoryGirl.create(:comment)
        atts = FactoryGirl.attributes_for(:comment, :body => 'I am new')
        put :update, :id => @comment.id, :comment => atts
      end

      it 'gets the comment' do
        expect(assigns[:comment]).to eq(@comment)
      end

      it 'updates the comment' do
        expect(Comment.find(@comment.id).body).to eq('I am new')
      end

      it 'logs the update event' do
        most_recent_event = Comment.find(@comment.id).info_request_events.last
        expect(most_recent_event.event_type).to eq('edit_comment')
        expect(most_recent_event.comment_id).to eq(@comment.id)
      end

      it 'shows a success notice' do
        expect(flash[:notice]).to eq("Comment successfully updated.")
      end

      it 'redirects to the request page' do
        expect(response).to redirect_to(admin_request_path(@comment.info_request))
      end
    end

    context 'on invalid data submission' do

      it 'renders the edit template' do
        @comment = FactoryGirl.create(:comment)
        put :update, :id => @comment.id, :comment => {:body => ''}
        expect(response).to render_template('edit')
      end

    end
  end

end
