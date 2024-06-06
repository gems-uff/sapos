# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ProfessorsController < ApplicationController
  authorize_resource

  include NumbersHelper
  include ApplicationHelper
  helper :professor_research_areas

  before_action :set_list_columns

  active_scaffold :professor do |config|
    config.columns.add :advisement_points
    config.columns.add :advisements_with_points
    config.list.columns = [
      :name, :cpf, :birthdate, :advisement_points, :enrollment_number
    ]
    config.list.sorting = { name: "ASC" }
    config.create.label = :create_professor_label
    config.columns[:advisement_points].sort_by method: "advisement_points_order"
    config.columns[:enrollments].associated_limit = nil
    config.columns[:birthdate].options = {
      data: CustomVariable.past_calendar_range
    }
    config.columns[:civil_status].form_ui = :select
    config.columns[:civil_status].options = {
      options: [["Solteiro(a)", "solteiro"], ["Casado(a)", "casado"]]
    }
    config.nested.add_link(:affiliations)
    config.columns[:sex].form_ui = :select
    config.columns[:sex].options = { options: [["Masculino", "M"],
                                               ["Feminino", "F"]] }
    config.columns[:scholarships].form_ui = :record_select
    config.columns[:professor_research_areas].includes = {
      research_areas: :professor_research_areas
    }
    config.columns[:identity_issuing_place].form_ui = ""
    config.columns[:identity_expedition_date].form_ui = :date_picker
    config.columns[:identity_expedition_date].options = {
      data: CustomVariable.past_calendar_range
    }
    config.columns[:academic_title_institution].form_ui = :record_select
    config.columns[:academic_title_country].form_ui = :select
    config.columns[:academic_title_level].form_ui = :select
    config.columns[:academic_title_date].options = {
      data: CustomVariable.past_calendar_range
    }

    form_columns = [
      :name, :email, :sex, :civil_status, :birthdate, :city, :neighborhood,
      :address, :zip_code, :telephone1, :telephone2, :cpf,
      :identity_expedition_date, :identity_issuing_body,
      :identity_issuing_place, :identity_number, :enrollment_number,
      :siape, :scholarships, :academic_title_level,
      :academic_title_institution, :academic_title_country,
      :academic_title_date, :obs, :professor_research_areas, :affiliations
    ]

    config.create.columns = form_columns
    config.update.columns = form_columns

    config.show.columns = [
      :name, :email, :cpf, :birthdate, :address, :birthdate, :civil_status,
      :identity_expedition_date, :identity_issuing_body, :identity_number,
      :neighborhood, :sex, :enrollment_number, :siape,
      :telephone1, :telephone2, :zip_code, :scholarships,
      :advisement_authorizations, :advisements_with_points,
      :academic_title_level, :academic_title_institution,
      :academic_title_country, :academic_title_date, :obs, :research_areas,
    ]

    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10,
    search_on: [:name],
    order_by: "name",
    full_text_search: true
  )

  def set_list_columns
    if Professor.first != nil

      Professor.instance_methods.grep(
        /^advisement_points_of_level/
      ).each do |advisement_points_of_level|
        active_scaffold_config.list.columns.exclude advisement_points_of_level
        Professor.undef_method advisement_points_of_level
      end

      levels_to_show = Level
        .where(show_advisements_points_in_list: true)
        .order(:short_name_showed_in_list_header)
      levels_to_add = []

      levels_to_show.each do |level|
        method_name = "advisement_points_of_level#{level.id}"
        Professor.first.create_advisement_points_of_level_method(method_name)
        active_scaffold_config.columns.add method_name
        levels_to_add.push(method_name)

        if level.short_name_showed_in_list_header.present?
          active_scaffold_config.columns[method_name].label =
            level.short_name_showed_in_list_header
        else
          active_scaffold_config.columns[method_name].label = level.name
        end
      end

      insert_position = Array(active_scaffold_config.list.columns)
        .find_index(:advisement_points) + 1
      Array(active_scaffold_config.list.columns).insert(
        insert_position, *levels_to_add
      )
    end
  end
end
