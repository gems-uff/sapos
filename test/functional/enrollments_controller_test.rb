# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'test_helper'

class EnrollmentsControllerTest < ActionController::TestCase
  setup do
    @enrollment = enrollments(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:enrollments)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create enrollment" do
    assert_difference('Enrollment.count') do
      post :create, :enrollment => @enrollment.attributes
    end

    assert_redirected_to enrollment_path(assigns(:enrollment))
  end

  test "should show enrollment" do
    get :show, :id => @enrollment.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @enrollment.to_param
    assert_response :success
  end

  test "should update enrollment" do
    put :update, :id => @enrollment.to_param, :enrollment => @enrollment.attributes
    assert_redirected_to enrollment_path(assigns(:enrollment))
  end

  test "should destroy enrollment" do
    assert_difference('Enrollment.count', -1) do
      delete :destroy, :id => @enrollment.to_param
    end

    assert_redirected_to enrollments_path
  end
end
