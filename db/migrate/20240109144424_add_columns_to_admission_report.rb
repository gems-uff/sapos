# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddColumnsToAdmissionReport < ActiveRecord::Migration[7.0]
  def change
    add_column :admission_report_groups, :in_simple, :boolean
    add_column :admission_report_groups, :pdf_format, :string
    remove_column :admission_report_configs, :group_column_simple_pdf, :string
    remove_column :admission_report_configs, :group_column_complete_pdf, :string
  end
end
