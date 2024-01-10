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
        "`countries`.`name` COLLATE :db_collation
          LIKE :country COLLATE :value_collation
        ", Collation.collations.merge(country: "%#{params[:country]}%")
      )
    end
    if params[:state].present?
      @cities = @cities.where(
        "`states`.`name` COLLATE :db_collation
          LIKE :state COLLATE :value_collation
         OR `states`.`code` COLLATE :db_collation
         LIKE :state COLLATE :value_collation
        ", Collation.collations.merge(state: "%#{params[:state]}%")
      )
    end
    @cities = @cities.where(
      "`cities`.`name` COLLATE :db_collation
        LIKE :city COLLATE :value_collation
      ", Collation.collations.merge(city: "%#{params[:term]}%")
    )
    @cities = @cities.limit(10)
    render json: @cities.map(&:name).uniq
  end

  def state
    @states = State
    if params[:state].present?
      @states = @states.joins(:country).where(
        "`countries`.`name` COLLATE :db_collation
          LIKE :country COLLATE :value_collation
        ", Collation.collations.merge(country: "%#{params[:country]}%")
      )
    end
    @states = @states.where(
      "`states`.`name` COLLATE :db_collation
        LIKE :state COLLATE :value_collation
        OR `states`.`code` COLLATE :db_collation
        LIKE :state COLLATE :value_collation
      ", Collation.collations.merge(state: "%#{params[:term]}%")
    )
    @states = @states.limit(10)
    render json: @states.map(&:name).uniq
  end

  def country
    @countries = Country.where(
      "name COLLATE :db_collation
        LIKE :country COLLATE :value_collation
      ", Collation.collations.merge(country: "%#{params[:term]}%")
    )
    @countries = @countries.limit(10)
    render json: @countries.map(&:name).uniq
  end

  def institution
    @institutions = Institution.where(
      "name COLLATE :db_collation
        LIKE :institution COLLATE :value_collation
       OR code COLLATE :db_collation
        LIKE :institution COLLATE :value_collation
      ", Collation.collations.merge(institution: "%#{params[:term]}%")
    )
    @institutions = @institutions.limit(10)
    render json: @institutions.map(&:name).uniq
  end

  def course
    @majors = Major
    if params[:institution].present?
      @majors = @majors.joins(:institution).where(
        "`institutions`.`name` COLLATE :db_collation
          LIKE :institution COLLATE :value_collation
        OR `institutions`.`code` COLLATE :db_collation
          LIKE :institution COLLATE :value_collation
        ", Collation.collations.merge(institution: "%#{params[:institution]}%")
      )
    end
    @majors = @majors.where(
      "`majors`.`name` COLLATE :db_collation
        LIKE :major COLLATE :value_collation
      ", Collation.collations.merge(major: "%#{params[:term]}%")
    )
    @majors = @majors.limit(10)
    result = @majors.map(&:name).uniq
    if result.empty?
      result = Major.where(
        "`majors`.`name` COLLATE :db_collation
          LIKE :major COLLATE :value_collation
        ", Collation.collations.merge(major: "%#{params[:term]}%")
      ).limit(10).map(&:name).uniq
    end
    render json: result
  end

end
