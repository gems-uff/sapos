# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FormTemplatesController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::FormTemplate" do |config|
    config.list.sorting = { name: "ASC" }
    config.create.label = :create_form_template_label

    config.list.columns = [:name, :description, :template_type]
    config.create.columns = [:name, :description, :template_type, :fields]
    config.update.columns = [:name, :description, :template_type, :fields]

    config.columns[:fields].show_blank_record = false
    config.columns[:template_type].form_ui = :select
    config.columns[:template_type].options = {
      options: [
        Admissions::FormTemplate::ADMISSION_FORM,
        Admissions::FormTemplate::RECOMMENDATION_LETTER,
      ]
    }

    config.actions << :duplicate
    config.duplicate.link.label = "
      <i title='#{I18n.t("active_scaffold.duplicate")}' class='fa fa-copy'></i>
    ".html_safe
    config.duplicate.link.method = :get
    config.duplicate.link.position = :after
    config.action_links.add "preview",
      label: "<i title='#{
        I18n.t "active_scaffold.admissions/form_template.preview.title"
      }' class='fa fa-play'></i>".html_safe,
      type: :member
    config.actions.exclude :deleted_records
  end
  record_select(
    per_page: 10, search_on: [:name], order_by: "name", full_text_search: true,
    model: "Admissions::FormTemplate"
  )

  def beginning_of_chain
    super.input_form
  end

  def preview
    @form_template = Admissions::FormTemplate.find(params[:id])
    @filled_form = Admissions::FilledForm.new(form_template: @form_template)
    filled_params = filled_form_params
    @notice = nil
    if filled_params.present?
      @filled_form.is_filled = true
      @filled_form.assign_attributes(filled_params)
      if @filled_form.valid?
        @notice = I18n.t("active_scaffold.admissions/form_template.preview.valid")
      end
      @filled_form.is_filled = false
    end
    @filled_form.prepare_missing_fields
  end

  def populate_field
    @scope = params[:scope]
    @parent_record = params[:id].nil? ?
      new_parent_record : find_if_allowed(params[:id], :update)

    if @parent_record.new_record?
      cache_generated_id(@parent_record, params[:generated_id])
    end
    @column = active_scaffold_config.columns[:fields]

    attribute_configs = [
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.initial_text"),
        field_type: Admissions::FormField::HTML,
        configuration: JSON.dump({
          "html": I18n.t("active_scaffold.admissions/form_template.generate_fields.initial_text_html")
        }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.personal_data"),
        field_type: Admissions::FormField::GROUP },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.name"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        sync: Admissions::FormField::SYNC_NAME,
        configuration: JSON.dump({ "field": "name", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.birthdate"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "birthdate", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.birth_city"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({"field": "special_birth_city", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.refugee"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "refugee", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.sex"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "sex", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.gender"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "gender", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.race_color"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "skin_color", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.deficiency"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "pcd", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.identity_or_passport"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "identity_number", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.identity_issuing_body"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "identity_issuing_body", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.identity_issuing_place"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "identity_issuing_place", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.identity_expedition_date"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "identity_expedition_date", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.cpf"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "cpf", "required": false }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.civil_status"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "civil_status", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.mother_name"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "mother_name", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.father_name"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "father_name" }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.address_group"),
        field_type: Admissions::FormField::GROUP },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.city"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({
          "field": "special_city",
          "required": true
        }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.address"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "special_address", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.neighborhood"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "neighborhood", "required": false }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.zip_code"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "zip_code", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.contact"),
        field_type: Admissions::FormField::GROUP },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.cellphone"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "telephone1", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.telephone"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "telephone2" }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.email"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        sync: Admissions::FormField::SYNC_EMAIL,
        configuration: JSON.dump({ "field": "email", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.scholarity"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        description: I18n.t("active_scaffold.admissions/form_template.generate_fields.scholarity_description"),
        configuration: JSON.dump({
          "field": "special_majors",
          "values": I18n.t("active_scaffold.admissions/form_template.generate_fields.scholarities").values,
          "statuses": I18n.t("active_scaffold.admissions/form_template.generate_fields.scholarity_statuses").values,
          "scholarity_grade_interval_description": I18n.t("active_scaffold.admissions/form_template.generate_fields.scholarity_grade_interval_description"),
        }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.job"),
        field_type: Admissions::FormField::GROUP },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.employer"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "employer" }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.job_position"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "job_position" }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.attachments"),
        field_type: Admissions::FormField::GROUP },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.photo"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        description: I18n.t("active_scaffold.admissions/form_template.generate_fields.photo_description"),
        configuration: JSON.dump({ "field": "photo" }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.identity_photo"),
        field_type: Admissions::FormField::FILE,
        description: I18n.t("active_scaffold.admissions/form_template.generate_fields.identity_photo_description"),
        configuration: JSON.dump({ "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.transcript"),
        description: I18n.t("active_scaffold.admissions/form_template.generate_fields.transcript_description"),
        field_type: Admissions::FormField::FILE },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.grades_report"),
        field_type: Admissions::FormField::FILE,
        description: I18n.t("active_scaffold.admissions/form_template.generate_fields.grades_report_description"),
        configuration: JSON.dump({ "required": true }) },
    ]

    @records = attribute_configs.collect do |attributes|
      record = build_associated(@column.association, @parent_record)
      record.assign_attributes(attributes)
      record
    end

    respond_to do |format|
      format.js {
        render action: "populate_field",
          formats: [:js],
          readonly: @column.association.readonly?
      }
    end
  end

  private
    def filled_form_params
      params.permit(
        record: Admissions::FilledFormsController.filled_form_params_definition
      )[:record]
    end
end
