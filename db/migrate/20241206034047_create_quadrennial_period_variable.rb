# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateQuadrennialPeriodVariable < ActiveRecord::Migration[7.0]
  def up
    CustomVariable.where(
      variable: "quadrennial_period"
    ).first || CustomVariable.create(
      description: "Periodo da Avaliação Quadrienal",
      variable: "quadrennial_period",
      value: "2021 - 2024"
    )
  end
end
