# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FormAutocompletesController < Admissions::ProcessBaseController

  def city
    @cities = City
    if params[:country].present? || params[:state].present?
      @cities = @cities.joins(:state)
    end
    if params[:country].present?
      @cities = @cities.joins(state: :country).where(
        "`countries`.`name` COLLATE utf8_unicode_ci LIKE ? COLLATE utf8_unicode_ci", "%#{params[:country]}%"
      )
    end
    if params[:state].present?
      @cities = @cities.where(
        "`states`.`name` COLLATE utf8_unicode_ci LIKE ? COLLATE utf8_unicode_ci", "%#{params[:state]}%"
      )
    end
    @cities = @cities.where(
      "`cities`.`name` COLLATE utf8_unicode_ci LIKE ? COLLATE utf8_unicode_ci", "%#{params[:term]}%"
    )
    render json: @cities.map(&:name).uniq
  end

  def state
    @states = State
    if params[:state].present?
      @states = @states.joins(:country).where(
        "`countries`.`name` COLLATE utf8_unicode_ci LIKE ? COLLATE utf8_unicode_ci", "%#{params[:country]}%"
      )
    end
    @states = @states.where(
      "`states`.`name` COLLATE utf8_unicode_ci LIKE ? COLLATE utf8_unicode_ci", "%#{params[:term]}%"
    )
    render json: @states.map(&:name).uniq
  end

  def country
    @countries = Country.where(
      "name COLLATE utf8_unicode_ci LIKE ? COLLATE utf8_unicode_ci", "%#{params[:term]}%"
    )
    render json: @countries.map(&:name).uniq
  end


end
