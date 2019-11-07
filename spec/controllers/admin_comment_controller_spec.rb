# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminCommentController do

  describe 'GET index' do
    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

    it 'sets the title' do
      get :index, session: { :user_id => admin_user.id }
      expect(assigns[:title]).to eq('Listing comments')
    end

    it 'collects comments by creation date' do
      Comment.destroy_all
      time_travel_to(1.month.ago)
      comment_1 = FactoryBot.create(:comment)
      back_to_the_present
      comment_2 = FactoryBot.create(:comment)
      get :index, session: { :user_id => admin_user.id }
      expect(assigns[:comments]).to eq([comment_2, comment_1])
    end

    it 'assigns the query' do
      get :index, params: { :query => 'hello' },
                  session: { :user_id => admin_user.id }
      expect(assigns[:query]).to eq('hello')
    end

    it 'filters comments by the search query' do
      Comment.destroy_all
      comment_1 = FactoryBot.create(:comment, :body => 'Hello world')
      comment_2 = FactoryBot.create(:comment, :body => 'Hi! hello world')
      comment_3 = FactoryBot.create(:comment, :body => 'xyz')
      get :index, params: { :query => 'hello' },
                  session: { :user_id => admin_user.id }
      expect(assigns[:comments]).to eq([comment_2, comment_1])
    end

    it 'renders the index template' do
      get :index, session: { :user_id => admin_user.id }
      expect(response).to render_template('index')
    end

    it 'responds successfully' do
      get :index, session: { :user_id => admin_user.id }
      expect(response).to be_successful
    end

    it 'does not include comments on embargoed requests if the current user is
        not a pro admin user' do
      comment = FactoryBot.create(:comment)
      comment.info_request.create_embargo
      get :index, session: { :user_id => admin_user.id }
      expect(assigns[:comments].include?(comment)).to be false
    end

    context 'if pro is enabled' do

      it 'does not include comments on embargoed requests if the
          current user is a pro admin user' do
        with_feature_enabled(:alaveteli_pro) do
          comment = FactoryBot.create(:comment)
          comment.info_request.create_embargo
          get :index, session: { :user_id => admin_user.id }
          expect(assigns[:comments].include?(comment)).to be false
        end
      end

      it 'includes comments on embargoed requests if the current user is a
          pro admin user' do
        with_feature_enabled(:alaveteli_pro) do
          comment = FactoryBot.create(:comment)
          comment.info_request.create_embargo
          get :index, session: { :user_id => pro_admin_user.id }
          expect(assigns[:comments].include?(comment)).to be true
        end
      end
    end

  end

  describe 'GET edit' do
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }
    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:comment) { FactoryBot.create(:comment) }

    it 'renders the edit template' do
      get :edit, params: { :id => comment.id },
                 session: { :user_id => admin_user.id }
      expect(response).to render_template('edit')
    end

    it 'gets the comment' do
      get :edit, params: { :id => comment.id },
                 session: { :user_id => admin_user.id }
      expect(assigns[:comment]).to eq(comment)
    end


    context 'if pro is enabled' do

      context 'if the current user cannot admin the comment' do

        it 'raises ActiveRecord::RecordNotFound' do
          with_feature_enabled(:alaveteli_pro) do
            comment.info_request.create_embargo
            expect {
              get :edit, params: { :id => comment.id },
                         session: { :user_id => admin_user.id }
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end

      context 'if the current user can admin the comment' do

        it 'renders the edit template' do
          with_feature_enabled(:alaveteli_pro) do
            comment.info_request.create_embargo
            get :edit, params: { :id => comment.id },
                       session: { :user_id => pro_admin_user.id }
            expect(response).to render_template('edit')
          end
        end
      end
    end
  end

  describe 'PUT update' do
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }
    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:comment) { FactoryBot.create(:comment) }
    let(:atts) { FactoryBot.attributes_for(:comment, :body => 'I am new') }

    context 'on valid data submission' do

      it 'gets the comment' do
        put :update, params: { :id => comment.id, :comment => atts },
                     session: { :user_id => admin_user.id }
        expect(assigns[:comment]).to eq(comment)
      end

      it 'updates the comment' do
        put :update, params: { :id => comment.id, :comment => atts },
                     session: { :user_id => admin_user.id }
        expect(Comment.find(comment.id).body).to eq('I am new')
      end

      it 'logs the update event' do
        put :update, params: { :id => comment.id, :comment => atts },
                     session: { :user_id => admin_user.id }
        most_recent_event = Comment.find(comment.id).info_request_events.last
        expect(most_recent_event.event_type).to eq('edit_comment')
        expect(most_recent_event.comment_id).to eq(comment.id)
      end

      context 'the attention_requested flag is the only change' do
        let(:atts) do
          FactoryBot.attributes_for(:comment,
                                    :body => comment.body,
                                    :attention_requested => true)
        end

        before do
          put :update, params: { :id => comment.id, :comment => atts },
                       session: { :user_id => admin_user.id }
        end

        it 'logs the update event' do
          most_recent_event = Comment.find(comment.id).info_request_events.last
          expect(most_recent_event.event_type).to eq('edit_comment')
        end

        it 'captures the old and new attention_requested values' do
          most_recent_event = Comment.find(comment.id).info_request_events.last
          expect(most_recent_event.params).
            to include(:old_attention_requested => false)
          expect(most_recent_event.params).
            to include(:attention_requested => true)
        end

        it 'updates the comment' do
          expect(Comment.find(comment.id).attention_requested).to eq(true)
        end

      end

      context 'the comment is being hidden' do

        context 'without changing the text' do

          it 'logs a "hide_comment" event' do
            atts = FactoryBot.attributes_for(:comment,
                                             :attention_requested => true,
                                             :visible => false)
            put :update, params: { :id => comment.id, :comment => atts },
                         session: { :user_id => admin_user.id }

            last_event = Comment.find(comment.id).info_request_events.last
            expect(last_event.event_type).to eq('hide_comment')
          end

        end

        context 'the text is changed as well' do

          it 'logs an "edit_comment" event' do
            atts = FactoryBot.attributes_for(:comment,
                                             :attention_requested => true,
                                             :visible => false,
                                             :body => 'updated text')
            put :update, params: { :id => comment.id, :comment => atts },
                         session: { :user_id => admin_user.id }

            last_event = Comment.find(comment.id).info_request_events.last
            expect(last_event.event_type).to eq('edit_comment')
          end

        end

      end

      it 'shows a success notice' do
        atts = FactoryBot.attributes_for(:comment,
                                         :attention_requested => true,
                                         :visible => false,
                                         :body => 'updated text')
        put :update, params: { :id => comment.id, :comment => atts },
                     session: { :user_id => admin_user.id }
        expect(flash[:notice]).to eq("Comment successfully updated.")
      end

      it 'redirects to the request page' do
        atts = FactoryBot.attributes_for(:comment,
                                         :attention_requested => true,
                                         :visible => false,
                                         :body => 'updated text')
        put :update, params: { :id => comment.id, :comment => atts },
                     session: { :user_id => admin_user.id }
        expect(response).to redirect_to(admin_request_path(comment.info_request))
      end
    end

    context 'on invalid data submission' do

      it 'renders the edit template' do
        with_feature_enabled(:alaveteli_pro) do
          put :update, params: {
                         :id => comment.id,
                         :comment => { :body => '' }
                       },
                       session: { :user_id => admin_user.id }
          expect(response).to render_template('edit')
        end
      end

    end


    context 'if pro is enabled' do

      context 'if the current user cannot admin the comment' do

        it 'raises ActiveRecord::RecordNotFound' do
          with_feature_enabled(:alaveteli_pro) do
            comment.info_request.create_embargo
            expect {
              put :update, params: { :id => comment.id },
                           session: { :user_id => admin_user.id }
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end

      context 'if the current user can admin the comment' do

        it 'updates the comment' do
          with_feature_enabled(:alaveteli_pro) do
            comment.info_request.create_embargo
            put :update, params: { :id => comment.id, :comment => atts },
                         session: { :user_id => pro_admin_user.id }
            expect(Comment.find(comment.id).body).to eq('I am new')
          end
        end
      end
    end
  end

end
