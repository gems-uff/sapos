# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ChangeFormFieldConfiguration < ActiveRecord::Migration[7.0]
  def up
    change_column :form_fields, :configuration, :text
  end
  def down
    change_column :form_fields, :configuration, :string
  end
end
