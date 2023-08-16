# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module ScholarshipsPdfHelper
  def scholarships_table(pdf, options = {})
    scholarships ||= options[:scholarships]

    widths = [110, 100, 80, 70, 100, 100]

    header = [[
      "<b>#{I18n.t('activerecord.attributes.scholarship.scholarship_number')}</b>",
      "<b>#{I18n.t('activerecord.attributes.scholarship.level')}</b>",
      "<b>#{I18n.t('activerecord.attributes.scholarship.sponsor')}</b>",
      "<b>#{I18n.t('activerecord.attributes.scholarship.scholarship_type')}</b>",
      "<b>#{I18n.t('activerecord.attributes.scholarship.start_date')}</b>",
      "<b>#{I18n.t('activerecord.attributes.scholarship.end_date')}</b>"
    ]]

    simple_pdf_table(pdf, widths, header, scholarships)
  end
end
