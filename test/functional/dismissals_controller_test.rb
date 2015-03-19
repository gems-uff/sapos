# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'test_helper'

class DismissalsControllerTest < ActionController::TestCase
  setup do
    @dismissal = dismissals(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dismissals)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dismissal" do
    assert_difference('Dismissal.count') do
      post :create, :dismissal => @dismissal.attributes
    end

    assert_redirected_to dismissal_path(assigns(:dismissal))
  end

  test "should show dismissal" do
    get :show, :id => @dismissal.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @dismissal.to_param
    assert_response :success
  end

  test "should update dismissal" do
    put :update, :id => @dismissal.to_param, :dismissal => @dismissal.attributes
    assert_redirected_to dismissal_path(assigns(:dismissal))
  end

  test "should destroy dismissal" do
    assert_difference('Dismissal.count', -1) do
      delete :destroy, :id => @dismissal.to_param
    end

    assert_redirected_to dismissals_path
  end
end
