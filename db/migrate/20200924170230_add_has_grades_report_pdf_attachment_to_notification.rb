# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddHasGradesReportPdfAttachmentToNotification < ActiveRecord::Migration[5.1]
  def self.up
    add_column :notifications, :has_grades_report_pdf_attachment, :boolean, default: false
  end

  def self.down
    remove_column :notifications, :has_grades_report_pdf_attachment
  end
end
