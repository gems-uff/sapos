# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'test_helper'

class ClassEnrollmentsControllerTest < ActionController::TestCase
  setup do
    @class_enrollment = class_enrollments(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:class_enrollments)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create class_enrollment" do
    assert_difference('ClassEnrollment.count') do
      post :create, :class_enrollment => @class_enrollment.attributes
    end

    assert_redirected_to class_enrollment_path(assigns(:class_enrollment))
  end

  test "should show class_enrollment" do
    get :show, :id => @class_enrollment.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @class_enrollment.to_param
    assert_response :success
  end

  test "should update class_enrollment" do
    put :update, :id => @class_enrollment.to_param, :class_enrollment => @class_enrollment.attributes
    assert_redirected_to class_enrollment_path(assigns(:class_enrollment))
  end

  test "should destroy class_enrollment" do
    assert_difference('ClassEnrollment.count', -1) do
      delete :destroy, :id => @class_enrollment.to_param
    end

    assert_redirected_to class_enrollments_path
  end
end
