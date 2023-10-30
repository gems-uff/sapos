# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class RenameFilledFormFieldScholaritiesDateToEndDateAndAddFields < ActiveRecord::Migration[7.0]
  def change
    rename_column :filled_form_field_scholarities, :date, :end_date
    add_column :filled_form_field_scholarities, :start_date, :string
    add_column :filled_form_field_scholarities, :institution, :string
    add_column :filled_form_field_scholarities, :course, :string
    add_column :filled_form_field_scholarities, :grade, :string
    add_column :filled_form_field_scholarities, :location, :string
  end
end
