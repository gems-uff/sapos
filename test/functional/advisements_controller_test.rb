require 'test_helper'

class AdvisementsControllerTest < ActionController::TestCase
  setup do
    @advisement = advisements(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:advisements)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create advisement" do
    assert_difference('Advisement.count') do
      post :create, :advisement => @advisement.attributes
    end

    assert_redirected_to advisement_path(assigns(:advisement))
  end

  test "should show advisement" do
    get :show, :id => @advisement.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @advisement.to_param
    assert_response :success
  end

  test "should update advisement" do
    put :update, :id => @advisement.to_param, :advisement => @advisement.attributes
    assert_redirected_to advisement_path(assigns(:advisement))
  end

  test "should destroy advisement" do
    assert_difference('Advisement.count', -1) do
      delete :destroy, :id => @advisement.to_param
    end

    assert_redirected_to advisements_path
  end
end
