# frozen_string_literal: true

module ReportsHelper
  include PdfHelper

  def create_external_report_pdf(report, document_data = {})
    render_to_string(
      template: "reports/external_report_pdf",
      type: "application/pdf",
      formats: [:pdf],
      assigns: { report: report, title: document_data[:title], document_body: document_data[:body], expiration_in_months: document_data[:expiration_in_months] }
    )
  end

  def report_body_text(pdf, document_body)
    pdf.bounding_box([(pdf.bounds.width - 500) / 2, pdf.cursor], width: 500, height: pdf.bounds.height - 98) do
      pdf.font("Times-Roman", size: 12) do
        pdf.fill_color "000000"
        pdf.move_down 30

        pdf.text document_body, align: :justify
      end
    end
  end

  def document_body_form_column(record, options)
    text_area :record, :document_body, options.merge!(rows: 20, cols: 80)
  end

  def document_title_form_column(record, options)
    text_field :record, :document_title, options.merge!(value: "DECLARAÇÃO")
  end

  def expiration_in_months_form_column(record, options)
    merge_options = { min: 1, value: ReportConfiguration.where(use_at_assertion: true).order(order: :desc).first&.expiration_in_months }
    number_field :record, :expiration_in_months, options.merge!(merge_options)
  end
end
