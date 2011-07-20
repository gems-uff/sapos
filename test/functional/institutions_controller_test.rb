require 'test_helper'

class InstitutionsControllerTest < ActionController::TestCase
  setup do
    @institution = institutions(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:institutions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create institution" do
    assert_difference('Institution.count') do
      post :create, :institution => @institution.attributes
    end

    assert_redirected_to institution_path(assigns(:institution))
  end

  test "should show institution" do
    get :show, :id => @institution.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @institution.to_param
    assert_response :success
  end

  test "should update institution" do
    put :update, :id => @institution.to_param, :institution => @institution.attributes
    assert_redirected_to institution_path(assigns(:institution))
  end

  test "should destroy institution" do
    assert_difference('Institution.count', -1) do
      delete :destroy, :id => @institution.to_param
    end

    assert_redirected_to institutions_path
  end
end
