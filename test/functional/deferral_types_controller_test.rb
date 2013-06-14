# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'test_helper'

class DeferralTypesControllerTest < ActionController::TestCase
  setup do
    @deferral_type = deferral_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:deferral_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create deferral_type" do
    assert_difference('DeferralType.count') do
      post :create, :deferral_type => @deferral_type.attributes
    end

    assert_redirected_to deferral_type_path(assigns(:deferral_type))
  end

  test "should show deferral_type" do
    get :show, :id => @deferral_type.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @deferral_type.to_param
    assert_response :success
  end

  test "should update deferral_type" do
    put :update, :id => @deferral_type.to_param, :deferral_type => @deferral_type.attributes
    assert_redirected_to deferral_type_path(assigns(:deferral_type))
  end

  test "should destroy deferral_type" do
    assert_difference('DeferralType.count', -1) do
      delete :destroy, :id => @deferral_type.to_param
    end

    assert_redirected_to deferral_types_path
  end
end
