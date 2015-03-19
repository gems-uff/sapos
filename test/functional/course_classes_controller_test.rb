# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'test_helper'

class CourseClassesControllerTest < ActionController::TestCase
  setup do
    @course_class = course_classes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:course_classes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create course_class" do
    assert_difference('CourseClass.count') do
      post :create, :course_class => @course_class.attributes
    end

    assert_redirected_to course_class_path(assigns(:course_class))
  end

  test "should show course_class" do
    get :show, :id => @course_class.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @course_class.to_param
    assert_response :success
  end

  test "should update course_class" do
    put :update, :id => @course_class.to_param, :course_class => @course_class.attributes
    assert_redirected_to course_class_path(assigns(:course_class))
  end

  test "should destroy course_class" do
    assert_difference('CourseClass.count', -1) do
      delete :destroy, :id => @course_class.to_param
    end

    assert_redirected_to course_classes_path
  end
end
