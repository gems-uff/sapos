# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'test_helper'

class EnrollmentStatusesControllerTest < ActionController::TestCase
  setup do
    @enrollment_status = enrollment_statuses(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:enrollment_statuses)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create enrollment_status" do
    assert_difference('EnrollmentStatus.count') do
      post :create, :enrollment_status => @enrollment_status.attributes
    end

    assert_redirected_to enrollment_status_path(assigns(:enrollment_status))
  end

  test "should show enrollment_status" do
    get :show, :id => @enrollment_status.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @enrollment_status.to_param
    assert_response :success
  end

  test "should update enrollment_status" do
    put :update, :id => @enrollment_status.to_param, :enrollment_status => @enrollment_status.attributes
    assert_redirected_to enrollment_status_path(assigns(:enrollment_status))
  end

  test "should destroy enrollment_status" do
    assert_difference('EnrollmentStatus.count', -1) do
      delete :destroy, :id => @enrollment_status.to_param
    end

    assert_redirected_to enrollment_statuses_path
  end
end
