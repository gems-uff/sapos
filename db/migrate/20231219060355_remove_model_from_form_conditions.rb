# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class RemoveModelFromFormConditions < ActiveRecord::Migration[7.0]
  def change
    remove_reference :form_conditions, :model, polymorphic: true, null: false
  end
end
