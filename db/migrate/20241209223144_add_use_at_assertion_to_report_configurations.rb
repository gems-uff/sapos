class AddUseAtAssertionToReportConfigurations < ActiveRecord::Migration[7.0]
  def change
    add_column :report_configurations, :use_at_assertion, :boolean, default: false, null: false
  end
end