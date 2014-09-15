require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SessionsController do

  describe 'DELETE destroy' do

      before(:each) do
        session[:user_id] = FactoryGirl.build(:user).id
      end

      it 'logs you out and redirects to the home page' do
          delete :destroy

          expect(session[:user_id]).to be_nil
          expect(response).to redirect_to(frontpage_path)
      end

      it 'logs you out and redirects you to where you were' do
          delete :destroy, :r => '/list'

          expect(session[:user_id]).to be_nil
          response.should redirect_to(request_list_path)
      end

      it 'clears the user_circumstance session' do
        session[:user_circumstance] = true

        delete :destroy
        expect(session[:user_circumstance]).to be_nil
      end

      it 'sets the remember_me session to false' do
        session[:remember_me] = true

        delete :destroy
        expect(session[:remember_me]).to be_false
      end

      it 'clears the using_admin session' do
        session[:using_admin] = true

        delete :destroy
        expect(session[:using_admin]).to be_nil
      end

      it 'clears the admin_name session' do
        session[:admin_name] = true

        delete :destroy
        expect(session[:admin_name]).to be_nil
      end   

  end

end
