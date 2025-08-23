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

    attribute_configs = Admissions::FormTemplate.sispos_sucupira_student_fields_config

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
