# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'test_helper'

class DeferralsControllerTest < ActionController::TestCase
  setup do
    @deferral = deferrals(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:deferrals)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create deferral" do
    assert_difference('Deferral.count') do
      post :create, :deferral => @deferral.attributes
    end

    assert_redirected_to deferral_path(assigns(:deferral))
  end

  test "should show deferral" do
    get :show, :id => @deferral.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @deferral.to_param
    assert_response :success
  end

  test "should update deferral" do
    put :update, :id => @deferral.to_param, :deferral => @deferral.attributes
    assert_redirected_to deferral_path(assigns(:deferral))
  end

  test "should destroy deferral" do
    assert_difference('Deferral.count', -1) do
      delete :destroy, :id => @deferral.to_param
    end

    assert_redirected_to deferrals_path
  end
end
