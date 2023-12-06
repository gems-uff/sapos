# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FilledFormsController < ApplicationController
  authorize_resource

  active_scaffold "Admissions::FilledForm" do |config|
    columns = [
      :form_template, :is_filled, :fields, :admission_application, :letter_request
    ]

    config.list.columns = columns
    config.show.columns = columns

    config.actions.exclude :deleted_records, :delete, :update, :create
  end

  protected
    def self.filled_form_params_definition
      [
        :id, :is_filled, :form_template_id,
        fields_attributes: [
          :id, :form_field_id, :value, :_destroy, :remove_file, :file,
          list: [],
          file: [
            :base64_contents, :filename
          ],
          scholarities_attributes: [
            :id, :level, :status, :institution, :course,
            :location, :grade, :grade_interval, :start_date, :end_date, :_destroy
          ],
        ]
      ]
    end
end
