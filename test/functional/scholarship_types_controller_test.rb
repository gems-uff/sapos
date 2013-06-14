# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'test_helper'

class ScholarshipTypesControllerTest < ActionController::TestCase
  setup do
    @scholarship_type = scholarship_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:scholarship_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create scholarship_type" do
    assert_difference('ScholarshipType.count') do
      post :create, :scholarship_type => @scholarship_type.attributes
    end

    assert_redirected_to scholarship_type_path(assigns(:scholarship_type))
  end

  test "should show scholarship_type" do
    get :show, :id => @scholarship_type.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @scholarship_type.to_param
    assert_response :success
  end

  test "should update scholarship_type" do
    put :update, :id => @scholarship_type.to_param, :scholarship_type => @scholarship_type.attributes
    assert_redirected_to scholarship_type_path(assigns(:scholarship_type))
  end

  test "should destroy scholarship_type" do
    assert_difference('ScholarshipType.count', -1) do
      delete :destroy, :id => @scholarship_type.to_param
    end

    assert_redirected_to scholarship_types_path
  end
end
