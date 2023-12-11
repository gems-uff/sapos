# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionCommitteesController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::AdmissionCommittee" do |config|
    config.create.label = :create_admission_committee_label

    columns = [
      :name, :members, :form_conditions, :admission_phases
    ]

    config.list.columns = columns
    config.show.columns = columns

    form_columns = [
      :name, :members, :form_conditions
    ]

    config.create.columns = form_columns
    config.update.columns = form_columns

    config.columns[:members].show_blank_record = false
    config.columns[:form_conditions].show_blank_record = false

    config.actions << :duplicate
    config.duplicate.link.label = "
      <i title='#{I18n.t("active_scaffold.duplicate")}' class='fa fa-copy'></i>
    ".html_safe
    config.duplicate.link.method = :get
    config.duplicate.link.position = :after
    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10, search_on: [:name], order_by: "name", full_text_search: true,
    model: "Admissions::AdmissionCommittee"
  )

  def populate_members(users)
    @scope = params[:scope]
    @parent_record = params[:id].nil? ?
      new_parent_record : find_if_allowed(params[:id], :update)

    if @parent_record.new_record?
      cache_generated_id(@parent_record, params[:generated_id])
    end
    @column = active_scaffold_config.columns[:members]

    attribute_configs = users.map do |u|
      { user: u }
    end

    @records = attribute_configs.collect do |attributes|
      record = build_associated(@column.association, @parent_record)
      record.assign_attributes(attributes)
      record
    end

    respond_to do |format|
      format.js {
        render action: "populate_members",
          formats: [:js],
          readonly: @column.association.readonly?
      }
    end
  end

  def populate_authorized
    populate_members(User.joins(professor: :advisement_authorizations).distinct)
  end

  def populate_professors
    populate_members(User.where(role_id: Role::ROLE_PROFESSOR))
  end

  def populate_coordination
    populate_members(User.where(role_id: Role::ROLE_COORDENACAO))
  end

  def populate_secretary
    populate_members(User.where(role_id: Role::ROLE_SECRETARIA))
  end
end
