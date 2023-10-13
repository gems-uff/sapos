# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FilledFormFieldScholarity < ActiveRecord::Base
  has_paper_trail

  belongs_to :filled_form_field, optional: false,
    class_name: "Admissions::FilledFormField"

  def to_label(values: nil, statuses: nil)
    level_label = self.level
    level_label = values[self.level] unless values.nil?
    status_label = self.status
    status_label = statuses[self.status] unless statuses.nil?
    result = level_label
    result = "#{result} - #{status_label}" if status_label.present?
    result = "#{result} (#{self.date})" if self.date.present?
    result
  end
end
