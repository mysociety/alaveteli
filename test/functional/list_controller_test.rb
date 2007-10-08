require File.dirname(__FILE__) + '/../test_helper'
require 'list_controller'

# Re-raise errors caught by the controller.
class ListController; def rescue_action(e) raise e end; end

class ListControllerTest < Test::Unit::TestCase
  def setup
    @controller = ListController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
