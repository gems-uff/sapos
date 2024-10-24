# frozen_string_literal: true

class AddExpiresAtToReportsTable < ActiveRecord::Migration[7.0]
  def up
    add_column :reports, :expires_at, :date, null: true
  end

  def down
    remove_column :reports, :expires_at
  end
end
