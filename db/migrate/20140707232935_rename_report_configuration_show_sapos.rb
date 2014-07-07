class RenameReportConfigurationShowSapos < ActiveRecord::Migration
  def change
  	rename_column :report_configurations, :show_sapos, :signature_footer
  end
end
