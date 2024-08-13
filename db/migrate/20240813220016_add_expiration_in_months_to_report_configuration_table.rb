# frozen_string_literal: true

class AddExpirationInMonthsToReportConfigurationTable < ActiveRecord::Migration[7.0]
  def up
    add_column :report_configurations, :expiration_in_months, :integer, null: true
  end

  def down
    remove_column :report_configurations, :expiration_in_months
  end
end
