# frozen_string_literal: true

class AddExpirationInMonthsToAssertions < ActiveRecord::Migration[7.0]
  def up
    add_column :assertions, :expiration_in_months, :integer, null: true
  end

  def down
    remove_column :assertions, :expiration_in_months
  end
end
