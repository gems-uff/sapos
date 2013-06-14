# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'test_helper'

class ProfessorResearchAreasControllerTest < ActionController::TestCase
  setup do
    @professor_research_area = professor_research_areas(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:professor_research_areas)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create professor_research_area" do
    assert_difference('ProfessorResearchArea.count') do
      post :create, :professor_research_area => @professor_research_area.attributes
    end

    assert_redirected_to professor_research_area_path(assigns(:professor_research_area))
  end

  test "should show professor_research_area" do
    get :show, :id => @professor_research_area.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @professor_research_area.to_param
    assert_response :success
  end

  test "should update professor_research_area" do
    put :update, :id => @professor_research_area.to_param, :professor_research_area => @professor_research_area.attributes
    assert_redirected_to professor_research_area_path(assigns(:professor_research_area))
  end

  test "should destroy professor_research_area" do
    assert_difference('ProfessorResearchArea.count', -1) do
      delete :destroy, :id => @professor_research_area.to_param
    end

    assert_redirected_to professor_research_areas_path
  end
end
