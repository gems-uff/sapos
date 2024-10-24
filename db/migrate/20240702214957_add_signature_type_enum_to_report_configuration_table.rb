# frozen_string_literal: true

class AddSignatureTypeEnumToReportConfigurationTable < ActiveRecord::Migration[7.0]
  def up
    add_column :report_configurations, :signature_type, :integer, default: 0
    ReportConfiguration.where(signature_footer: true).update_all(signature_type: 1)
    ReportConfiguration.where(qr_code_signature: true).update_all(signature_type: 2)
    remove_column :report_configurations, :signature_footer
    remove_column :report_configurations, :qr_code_signature
  end

  def down
    add_column :report_configurations, :signature_footer, :boolean, default: false
    add_column :report_configurations, :qr_code_signature, :boolean, default: false
    ReportConfiguration.where(signature_type: 1).update_all(signature_footer: true)
    ReportConfiguration.where(signature_type: 2).update_all(qr_code_signature: true)
    remove_column :report_configurations, :signature_type
  end
end
