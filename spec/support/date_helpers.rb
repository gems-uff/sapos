# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Fix running tests in the first day of the month

module DateHelpers
  def middle_of_month(date)
    Date.new(date.year, date.month, 15)
  end

  def select_month_year_i(field, date)
    month_text = I18n.l(date, format: "%B")[0..2]  # Fix for "Março"
    find(:select, "#{field}_2i").find(:option, text: month_text).select_option
    find(:select, "#{field}_1i").find(:option, text: date.year.to_s).select_option
  end

  def select_month_year(field, date)
    month_text = I18n.l(date, format: "%B")[0..2]  # Fix for "Março"
    find(:select, "#{field}_month").find(:option, text: month_text).select_option
    find(:select, "#{field}_year").find(:option, text: date.year.to_s).select_option
  end

  # Uses waiting matchers (have_select) instead of page.all, which asserted on
  # whatever was in the DOM at that instant and failed if the AJAX-loaded form
  # had not rendered the widget yet.
  def expect_to_have_month_year_widget_i(record, field, blank = nil)
    months = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
    months = [blank] + months unless blank.nil?
    expect(page).to have_select("record_#{field}_2i", options: months)
    expect(page).to have_select("record_#{field}_1i", with_options: [1.years.ago.year.to_s, 1.years.since.year.to_s])
  end
end
