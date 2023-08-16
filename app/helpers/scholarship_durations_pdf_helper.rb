# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module ScholarshipDurationsPdfHelper
  def scholarship_durations_table(pdf, options = {})
    scholarship_durations ||= options[:scholarship_durations]

    widths = [112, 112, 112, 112, 112]

    header = [[
      "<b>#{I18n.t('activerecord.attributes.scholarship_duration.scholarship')}</b>",
      "<b>#{I18n.t('activerecord.attributes.scholarship_duration.start_date')}</b>",
      "<b>#{I18n.t('activerecord.attributes.scholarship_duration.end_date')}</b>",
      "<b>#{I18n.t('activerecord.attributes.scholarship_duration.cancel_date')}</b>",
      "<b>#{I18n.t('activerecord.attributes.scholarship_duration.enrollment')}</b>"
    ]]
    simple_pdf_table(pdf, widths, header, scholarship_durations)
  end
end
