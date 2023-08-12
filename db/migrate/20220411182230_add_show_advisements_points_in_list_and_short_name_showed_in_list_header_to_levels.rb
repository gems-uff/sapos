# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddShowAdvisementsPointsInListAndShortNameShowedInListHeaderToLevels < ActiveRecord::Migration[6.0]
  def up
    change_table :levels do |t|
      t.boolean :show_advisements_points_in_list
      t.string :short_name_showed_in_list_header
    end
  end

  def down
    change_table :levels do |t|
      t.remove :show_advisements_points_in_list
      t.remove :short_name_showed_in_list_header
    end
  end
end
