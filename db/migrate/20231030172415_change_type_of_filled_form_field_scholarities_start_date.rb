# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ChangeTypeOfFilledFormFieldScholaritiesStartDate < ActiveRecord::Migration[7.0]
  def up
    change_column :filled_form_field_scholarities, :start_date, :date
    add_column :filled_form_field_scholarities, :grade_interval, :string
  end

  def down
    change_column :filled_form_field_scholarities, :start_date, :string
    remove_column :filled_form_field_scholarities, :grade_interval
  end
end
