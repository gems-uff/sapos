class AddAssertionReportConfiguration < ActiveRecord::Migration[7.0]
  def up
    ReportConfiguration.reset_column_information
    report_configuration = {
      name: "Declaração",
      scale: 1,
      x: 0,
      y: 0,
      order: 1,
      signature_type: 2,
      use_at_report: false,
      use_at_transcript: false,
      use_at_grades_report: false,
      use_at_schedule: false,
      use_at_assertion: true,
      text: <<~TEXT
        <NOME DA UNIVERSIDADE>
        <NOME DO INSTITUTO>
        <NOME DO PROGRAMA>
      TEXT
    }

    report_configuration_obj = ReportConfiguration.new(report_configuration)
    report_configuration_obj.save!
  end

  def down
    report_configuration = ReportConfiguration.find_by(name: "Declaração")
    report_configuration.destroy if report_configuration
  end
end