# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddAcademicTitleFieldsToProfessors < ActiveRecord::Migration[5.1]
  def change
    add_column :professors, :academic_title_date, :date
    add_column(
      :professors, :academic_title_country_id, :integer,
      references: :countries
    )
    add_column(
      :professors, :academic_title_institution_id, :integer,
      references: :institutions
    )
    add_column(
      :professors, :academic_title_level_id, :integer,
      references: :levels
    )
    add_index :professors, :academic_title_country_id
    add_index :professors, :academic_title_institution_id
    add_index :professors, :academic_title_level_id
  end
end
