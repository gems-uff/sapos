# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddImportGradesSessionTimeoutCustomVariable < ActiveRecord::Migration[8.1]
  # Classe minima da propria migration nao depende do modelo da aplicacao
  class MigrationCustomVariable < ActiveRecord::Base
    self.table_name = "custom_variables"
  end

  VARIABLE = "import_grades_session_timeout"

  def up
    return if MigrationCustomVariable.exists?(variable: VARIABLE)

    MigrationCustomVariable.create!(
      variable: VARIABLE,
      description: "Tempo, em minutos, que a prévia de importação de notas fica válida",
      value: "45"
    )
  end

  def down
    MigrationCustomVariable.where(variable: VARIABLE).delete_all
  end
end