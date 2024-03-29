# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddShowAdvisorNameToDismissalReason < ActiveRecord::Migration[5.1]
  def change
    add_column :dismissal_reasons, :show_advisor_name, :boolean, default: false
  end
end
