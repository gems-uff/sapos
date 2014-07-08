class ChangeReportConfigurationsScaleType < ActiveRecord::Migration
  def change
  	change_column :report_configurations, :scale, :decimal, :precision => 10, :scale => 8
  end
end
