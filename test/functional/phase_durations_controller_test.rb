require 'test_helper'

class PhaseDurationsControllerTest < ActionController::TestCase
  setup do
    @phase_duration = phase_durations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:phase_durations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create phase_duration" do
    assert_difference('PhaseDuration.count') do
      post :create, :phase_duration => @phase_duration.attributes
    end

    assert_redirected_to phase_duration_path(assigns(:phase_duration))
  end

  test "should show phase_duration" do
    get :show, :id => @phase_duration.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @phase_duration.to_param
    assert_response :success
  end

  test "should update phase_duration" do
    put :update, :id => @phase_duration.to_param, :phase_duration => @phase_duration.attributes
    assert_redirected_to phase_duration_path(assigns(:phase_duration))
  end

  test "should destroy phase_duration" do
    assert_difference('PhaseDuration.count', -1) do
      delete :destroy, :id => @phase_duration.to_param
    end

    assert_redirected_to phase_durations_path
  end
end
