# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class StudentsController < ApplicationController
  authorize_resource

  helper :student_majors

  UPDATE_FIELDS = [
    :name, :photo, :sex, :civil_status, :birthdate, :city, :neighborhood,
    :address, :zip_code, :telephone1, :telephone2, :email, :employer,
    :job_position, :cpf, :identity_number, :identity_issuing_body,
    :identity_issuing_place, :identity_expedition_date, :birth_country,
    :birth_state, :birth_city, :father_name, :mother_name, :obs,
    :student_majors
  ]

  before_action :check_current_user

  active_scaffold :student do |config|
    config.list.sorting = { name: "ASC" }
    config.list.columns = [:name, :cpf, :enrollments]
    config.create.label = :create_student_label

    config.columns[:birthdate].options = {
      data: CustomVariable.past_calendar_range
    }
    config.columns[:identity_expedition_date].options = {
      data: CustomVariable.past_calendar_range
    }
    config.columns[:birth_city].form_ui = :select
    config.columns[:birth_state].form_ui = :hidden
    config.columns[:birth_country].form_ui = :hidden
    config.columns[:city].form_ui = :select
    config.columns[:identity_issuing_place].form_ui = ""

    config.columns[:sex].form_ui = :select
    config.columns[:sex].options = {
      options: [["Masculino", "M"], ["Feminino", "F"]]
    }
    config.columns[:civil_status].form_ui = :select
    config.columns[:civil_status].options = {
      options: ["Solteiro(a)", "Casado(a)"]
    }

    config.columns[:student_majors].includes = [:majors, :student_majors]

    config.columns = UPDATE_FIELDS

    config.actions.exclude :deleted_records
  end

  record_select(
    per_page: 10, search_on: [:name], order_by: "name", full_text_search: true
  )

  def photo
    student = Student.find params[:id]
    send_data student.photo.read, filename: student.photo_identifier
  end

  private
    def check_current_user
      if can? :update_all_fields, Student
        active_scaffold_config.update.columns = UPDATE_FIELDS
      elsif can? :update_only_photo, Student
        active_scaffold_config.update.columns = [:photo, :email]
      end
      if can? :read_all_fields, Student
        active_scaffold_config.show.columns = UPDATE_FIELDS
      elsif can? :update_only_photo, Student
        active_scaffold_config.update.columns = [:photo, :email]
      end
    end
end
