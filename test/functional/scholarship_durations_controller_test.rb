require 'test_helper'

class ScholarshipDurationsControllerTest < ActionController::TestCase
  setup do
    @scholarship_duration = scholarship_durations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:scholarship_durations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create scholarship_duration" do
    assert_difference('ScholarshipDuration.count') do
      post :create, :scholarship_duration => @scholarship_duration.attributes
    end

    assert_redirected_to scholarship_duration_path(assigns(:scholarship_duration))
  end

  test "should show scholarship_duration" do
    get :show, :id => @scholarship_duration.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @scholarship_duration.to_param
    assert_response :success
  end

  test "should update scholarship_duration" do
    put :update, :id => @scholarship_duration.to_param, :scholarship_duration => @scholarship_duration.attributes
    assert_redirected_to scholarship_duration_path(assigns(:scholarship_duration))
  end

  test "should destroy scholarship_duration" do
    assert_difference('ScholarshipDuration.count', -1) do
      delete :destroy, :id => @scholarship_duration.to_param
    end

    assert_redirected_to scholarship_durations_path
  end
end
