class AddAssertionReportConfiguration < ActiveRecord::Migration[7.0]
  def up
    ReportConfiguration.reset_column_information
    report_configuration_pattern = ReportConfiguration.find_by_name("Padrão")
    if !report_configuration_pattern
      report_configuration_pattern = ReportConfiguration.all.order(:order).first
    end

    report_configuration = report_configuration_pattern.dup
    report_configuration.name = "Declaração"
    report_configuration.signature_type = 2
    report_configuration.use_at_assertion = true
    report_configuration.use_at_report = false
    report_configuration.use_at_transcript = false
    report_configuration.use_at_grades_report = false
    report_configuration.use_at_schedule = false

    report_configuration_obj = ReportConfiguration.new(report_configuration.attributes)
    report_configuration_obj.save!
  end

  def down
    report_configuration = ReportConfiguration.find_by(name: "Declaração")
    report_configuration.destroy if report_configuration
  end
end