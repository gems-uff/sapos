# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Assertion < ApplicationRecord
  has_paper_trail

  @@disable_erb_validation = false
  LIQUID = record_i18n_attr("template_types.liquid")
  ERB = record_i18n_attr("template_types.erb")

  TEMPLATE_TYPES = [LIQUID, ERB]

  attr_accessor :args
  belongs_to :query, inverse_of: :assertions, optional: false

  validates :name, presence: true
  validates :assertion_template, presence: true, on: :update
  validates :expiration_in_months, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :template_type, presence: true, inclusion: { in: TEMPLATE_TYPES }, allow_blank: false
  validate :only_student_enrollment_param, if: -> { self.student_can_generate }
  validate :cannot_create_new_erb_template, if: -> { self.template_type == ERB } 

  scope :student_allowed, -> { where(student_can_generate: true) }

  def to_label
    "#{self.name}"
  end

  def query_results(args=nil)
    self.query.execute(args || self.args)
  end
   
  def format_text(args=nil)
    results = self.query_results(args)
    rows = results[:rows]
    columns = results[:columns]
    raise Exceptions::EmptyQueryException if rows.empty?

    unique_columns = columns.select do |column|
      rows.all? { |row| row[columns.index(column)] == rows.first[columns.index(column)] }
    end
    bindings = {
      rows: rows,
      columns: columns
    }.merge(Hash[unique_columns.zip(rows.first.values_at(*unique_columns.map { |col| columns.index(col) }))])

    formatter = FormatterFactory.create_formatter(bindings, self.template_type)
    formatter.format(self.assertion_template)
  end


  def self.disable_erb_validation!
    @@disable_erb_validation = true
    yield
    @@disable_erb_validation = false
  end

  private
    def only_student_enrollment_param
      if self.query.params.pluck(:name) != ["matricula_aluno"]
        errors.add(:student_can_generate, :default_enrollment_variable_required)
      end
    end

    def cannot_create_new_erb_template
      return if @@disable_erb_validation
      assertion = self.paper_trail.previous_version
      current = I18n.transliterate(self.assertion_template).downcase
      while assertion.present?
        old = I18n.transliterate(assertion.assertion_template).downcase
        if current == old && assertion.template_type == ERB
          return
        end
        assertion = assertion.paper_trail.previous_version
      end
      errors.add(:assertion_template, :cannot_create_new_erb_template)
    end
end
