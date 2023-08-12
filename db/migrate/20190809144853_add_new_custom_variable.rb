# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddNewCustomVariable < ActiveRecord::Migration[5.1]
  def change
    CustomVariable.where(
      variable: "professor_login_can_post_grades"
    ).first || CustomVariable.create(
      variable: "professor_login_can_post_grades",
      value: "no"
    )
  end
end
