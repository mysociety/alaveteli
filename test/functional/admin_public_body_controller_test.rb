require File.dirname(__FILE__) + '/../test_helper'
require 'admin_public_body_controller'

# Re-raise errors caught by the controller.
class AdminPublicBodyController; def rescue_action(e) raise e end; end

class AdminPublicBodyControllerTest < Test::Unit::TestCase
  fixtures :public_bodies

  def setup
    @controller = AdminPublicBodyController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = public_bodies(:one).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:public_bodies)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:public_body)
    assert assigns(:public_body).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:public_body)
  end

  def test_create
    num_public_bodies = PublicBody.count

    post :create, :public_body => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_public_bodies + 1, PublicBody.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:public_body)
    assert assigns(:public_body).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      PublicBody.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      PublicBody.find(@first_id)
    }
  end
end
