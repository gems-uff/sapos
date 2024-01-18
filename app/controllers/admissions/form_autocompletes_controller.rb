# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FormAutocompletesController < Admissions::ProcessBaseController
  def city
    @cities = City.search_name(
      city: params[:term],
      state: params[:state],
      country: params[:country],
      substring: true
    ).limit(10)
    render json: @cities.map(&:name).uniq
  end

  def state
    @states = State.search_name(
      state: params[:term],
      country: params[:country],
      substring: true
    ).limit(10)
    render json: @states.map(&:name).uniq
  end

  def country
    @countries = Country.search_name(
      country: params[:term],
      substring: true
    ).limit(10)
    render json: @countries.map(&:name).uniq
  end

  def institution
    @institutions = Institution.search_name(
      institution: params[:term],
      substring: true
    ).limit(10)
    render json: @institutions.map(&:name).uniq
  end

  def course
    @majors = Major.search_name(
      major: params[:term],
      institution: params[:institution],
      substring: true,
      ignore_association: true
    ).limit(10)
    result = @majors.map(&:name).uniq
    render json: result
  end

  def form_field
    @form_fields = Admissions::FormField.full_search_name(
      field: params[:term],
      in_letter: params[:in_letter] || false,
      substring: true,
      limit: 10
    )
    render json: @form_fields.uniq
  end
end
