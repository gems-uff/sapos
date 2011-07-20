require 'test_helper'

class DismissalReasonsControllerTest < ActionController::TestCase
  setup do
    @dismissal_reason = dismissal_reasons(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dismissal_reasons)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dismissal_reason" do
    assert_difference('DismissalReason.count') do
      post :create, :dismissal_reason => @dismissal_reason.attributes
    end

    assert_redirected_to dismissal_reason_path(assigns(:dismissal_reason))
  end

  test "should show dismissal_reason" do
    get :show, :id => @dismissal_reason.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @dismissal_reason.to_param
    assert_response :success
  end

  test "should update dismissal_reason" do
    put :update, :id => @dismissal_reason.to_param, :dismissal_reason => @dismissal_reason.attributes
    assert_redirected_to dismissal_reason_path(assigns(:dismissal_reason))
  end

  test "should destroy dismissal_reason" do
    assert_difference('DismissalReason.count', -1) do
      delete :destroy, :id => @dismissal_reason.to_param
    end

    assert_redirected_to dismissal_reasons_path
  end
end
