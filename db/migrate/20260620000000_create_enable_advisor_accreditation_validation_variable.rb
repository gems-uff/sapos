# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateEnableAdvisorAccreditationValidationVariable < ActiveRecord::Migration[7.0]
  def up
    CustomVariable.where(variable: "enable_advisor_accreditation_validation").first ||
      CustomVariable.create(
        description: "Ativa a validação de credenciamento de orientadores no nível da matrícula (yes/no)",
        variable: "enable_advisor_accreditation_validation",
        value: "yes"
      )
  end

  def down
    CustomVariable.where(variable: "enable_advisor_accreditation_validation").destroy_all
  end
end
