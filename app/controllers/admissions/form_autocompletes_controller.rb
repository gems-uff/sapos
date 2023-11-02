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
        "`countries`.`name` COLLATE utf8mb4_unicode_520_ci
          LIKE ? COLLATE utf8mb4_unicode_520_ci", "%#{params[:country]}%"
      )
    end
    if params[:state].present?
      @cities = @cities.where(
        "`states`.`name` COLLATE utf8mb4_unicode_520_ci
          LIKE ? COLLATE utf8mb4_unicode_520_ci
         OR `states`.`code` COLLATE utf8mb4_unicode_520_ci
         LIKE ? COLLATE utf8mb4_unicode_520_ci
        ", "%#{params[:state]}%", "%#{params[:state]}%"
      )
    end
    @cities = @cities.where(
      "`cities`.`name` COLLATE utf8mb4_unicode_520_ci
        LIKE ? COLLATE utf8mb4_unicode_520_ci", "%#{params[:term]}%"
    )
    @cities = @cities.limit(10)
    render json: @cities.map(&:name).uniq
  end

  def state
    @states = State
    if params[:state].present?
      @states = @states.joins(:country).where(
        "`countries`.`name` COLLATE utf8mb4_unicode_520_ci
          LIKE ? COLLATE utf8mb4_unicode_520_ci", "%#{params[:country]}%"
      )
    end
    @states = @states.where(
      "`states`.`name` COLLATE utf8mb4_unicode_520_ci
        LIKE ? COLLATE utf8mb4_unicode_520_ci
        OR `states`.`code` COLLATE utf8mb4_unicode_520_ci
        LIKE ? COLLATE utf8mb4_unicode_520_ci
      ", "%#{params[:term]}%", "%#{params[:term]}%"
    )
    @states = @states.limit(10)
    render json: @states.map(&:name).uniq
  end

  def country
    @countries = Country.where(
      "name COLLATE utf8mb4_unicode_520_ci
        LIKE ? COLLATE utf8mb4_unicode_520_ci", "%#{params[:term]}%"
    )
    @countries = @countries.limit(10)
    render json: @countries.map(&:name).uniq
  end

  def institution
    @institutions = Institution.where(
      "name COLLATE utf8mb4_unicode_520_ci
        LIKE ? COLLATE utf8mb4_unicode_520_ci
       OR code COLLATE utf8mb4_unicode_520_ci
        LIKE ? COLLATE utf8mb4_unicode_520_ci
      ", "%#{params[:term]}%", "%#{params[:term]}%"
    )
    @institutions = @institutions.limit(10)
    render json: @institutions.map(&:name).uniq
  end

  def course
    @majors = Major
    if params[:institution].present?
      @majors = @majors.joins(:institution).where(
        "`institutions`.`name` COLLATE utf8mb4_unicode_520_ci
          LIKE ? COLLATE utf8mb4_unicode_520_ci
        OR `institutions`.`code` COLLATE utf8mb4_unicode_520_ci
          LIKE ? COLLATE utf8mb4_unicode_520_ci
        ", "%#{params[:institution]}%", "%#{params[:institution]}%"
      )
    end
    @majors = @majors.where(
      "`majors`.`name` COLLATE utf8mb4_unicode_520_ci
        LIKE ? COLLATE utf8mb4_unicode_520_ci", "%#{params[:term]}%"
    )
    @majors = @majors.limit(10)
    result = @majors.map(&:name).uniq
    if result.empty?
      result = Major.where(
        "`majors`.`name` COLLATE utf8mb4_unicode_520_ci
          LIKE ? COLLATE utf8mb4_unicode_520_ci", "%#{params[:term]}%"
      ).limit(10).map(&:name).uniq
    end
    render json: result
  end

end
