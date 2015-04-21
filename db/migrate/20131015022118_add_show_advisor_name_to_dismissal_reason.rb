# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddShowAdvisorNameToDismissalReason < ActiveRecord::Migration
  def change
    add_column :dismissal_reasons, :show_advisor_name, :boolean, default: false
  end
end
