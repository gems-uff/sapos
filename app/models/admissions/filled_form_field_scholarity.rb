# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FilledFormFieldScholarity < ActiveRecord::Base
  has_paper_trail

  belongs_to :filled_form_field, optional: false,
    class_name: "Admissions::FilledFormField"


  validates_date :start_date, allow_blank: true
  validates_date :end_date, allow_blank: true
  validate :that_value_follows_configuration_rules


  def that_value_follows_configuration_rules
    return if self.filled_form_field.nil?
    return if self.filled_form_field.form_field.nil?
    configuration = JSON.parse(
      self.filled_form_field.form_field.configuration || "{}"
    )
    [
      { name: :level, type: :select },
      { name: :status, type: :select },
      { name: :institution, type: :text },
      { name: :course, type: :text },
      { name: :location, type: :location },
      { name: :grade, type: :text },
      { name: :grade_interval, type: :text },
      { name: :start_date, type: :date },
      { name: :end_date, type: :date },
    ].each do |field|
      if configuration["scholarity_#{field[:name]}_required"] && self[field[:name]].blank?
        label = configuration["scholarity_#{field[:name]}_name"] || I18n.t(
          "activerecord.attributes.admissions/filled_form_field_scholarity.#{field[:name]}"
        )
        self.filled_form_field.add_error(:scholarity_blank, attr: label)
      end
    end
  end


  def to_label(values: nil, statuses: nil)
    level_label = self.level
    level_label = values[self.level] unless values.nil?
    status_label = self.status
    status_label = statuses[self.status] unless statuses.nil?
    result = [
      level_label, status_label, self.institution, self.course,
      self.location, self.grade
    ].reject(&:blank?).join(" - ")

    date = [
      self.start_date, self.end_date
    ].reject(&:blank?).join(" - ")

    result = "#{result} (#{date})" if date.present?
    result
  end
end
