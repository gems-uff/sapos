# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

new_document('to_pdf.pdf', I18n.t('pdf_content.application_processes.to_pdf.filename'), :pdf_type => :report) do |pdf|
  student_applications_complete_table(pdf, application_process: @application_process)
  pdf.font('Courier', :size => 8) do
    options = { :at => [pdf.bounds.right - 100, -10],
                :width => 100,
                :align => :right
    }
    pdf.number_pages "#{I18n.t("pdf_content.enrollment.footer.page")}<page>/<total>", options
  end

end