# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'test_helper'

class AllocationsControllerTest < ActionController::TestCase
  setup do
    @allocation = allocations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:allocations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create allocation" do
    assert_difference('Allocation.count') do
      post :create, :allocation => @allocation.attributes
    end

    assert_redirected_to allocation_path(assigns(:allocation))
  end

  test "should show allocation" do
    get :show, :id => @allocation.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @allocation.to_param
    assert_response :success
  end

  test "should update allocation" do
    put :update, :id => @allocation.to_param, :allocation => @allocation.attributes
    assert_redirected_to allocation_path(assigns(:allocation))
  end

  test "should destroy allocation" do
    assert_difference('Allocation.count', -1) do
      delete :destroy, :id => @allocation.to_param
    end

    assert_redirected_to allocations_path
  end
end
