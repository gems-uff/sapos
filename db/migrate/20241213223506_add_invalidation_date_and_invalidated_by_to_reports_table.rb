# frozen_string_literal: true

class AddInvalidationDateAndInvalidatedByToReportsTable < ActiveRecord::Migration[7.0]
  def up
    add_reference :reports, :invalidated_by, foreign_key: { to_table: :users }
    add_column :reports, :invalidated_at, :datetime
  end

  def down
    remove_column :reports, :invalidated_at
    remove_reference :reports, :invalidated_by, foreign_key: true
  end
end
