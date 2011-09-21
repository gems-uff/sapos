require 'test_helper'

class CitiesControllerTest < ActionController::TestCase
  setup do
    @city = cities(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:cities)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create city" do
    assert_difference('City.count') do
      post :create, :city => @city.attributes
    end

    assert_redirected_to city_path(assigns(:city))
  end

  test "should show city" do
    get :show, :id => @city.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @city.to_param
    assert_response :success
  end

  test "should update city" do
    put :update, :id => @city.to_param, :city => @city.attributes
    assert_redirected_to city_path(assigns(:city))
  end

  test "should destroy city" do
    assert_difference('City.count', -1) do
      delete :destroy, :id => @city.to_param
    end

    assert_redirected_to cities_path
  end
end
