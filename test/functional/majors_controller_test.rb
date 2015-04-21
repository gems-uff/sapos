# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'test_helper'

class MajorsControllerTest < ActionController::TestCase
  setup do
    @major = majors(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:majors)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create major" do
    assert_difference('Course.count') do
      post :create, :major => @major.attributes
    end

    assert_redirected_to major_path(assigns(:major))
  end

  test "should show major" do
    get :show, :id => @major.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @major.to_param
    assert_response :success
  end

  test "should update major" do
    put :update, :id => @major.to_param, :major => @major.attributes
    assert_redirected_to major_path(assigns(:major))
  end

  test "should destroy major" do
    assert_difference('Course.count', -1) do
      delete :destroy, :id => @major.to_param
    end

    assert_redirected_to majors_path
  end
end
