# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::RankingConfig < ActiveRecord::Base
  has_paper_trail

  has_many :ranking_columns, dependent: :destroy,
    class_name: "Admissions::RankingColumn"
  has_many :ranking_groups, dependent: :destroy,
    class_name: "Admissions::RankingGroup"
  has_many :ranking_processes, dependent: :destroy,
    class_name: "Admissions::RankingProcess"
  has_many :admission_process_rankings, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionProcessRanking"
  has_many :admission_ranking_results, dependent: :destroy,
    class_name: "Admissions::AdmissionRankingResult"

  belongs_to :form_template, optional: true,
    class_name: "Admissions::FormTemplate"
  belongs_to :position_field, optional: true,
    class_name: "Admissions::FormField", foreign_key: "position_field_id"
  belongs_to :machine_field, optional: true,
    class_name: "Admissions::FormField", foreign_key: "machine_field_id"

  validates :name, presence: true
  validates :ranking_columns, length: { minimum: 1 }
  validates :ranking_processes, length: { minimum: 1 }

  accepts_nested_attributes_for :form_template, allow_destroy: false
  accepts_nested_attributes_for :position_field, allow_destroy: false
  accepts_nested_attributes_for :machine_field, allow_destroy: false

  before_validation :create_form_template

  def create_form_template
    if self.form_template.blank?
      self.form_template = Admissions::FormTemplate.new(
        name: self.name,
        template_type: Admissions::FormTemplate::RANKING
      )
      self.position_field = self.form_template.fields.build(
        field_type: Admissions::FormField::NUMBER
      )
      self.machine_field = self.form_template.fields.build(
        field_type: Admissions::FormField::STRING
      )
    end
    self.form_template.name = self.name
    self.position_field.name = "#{record_i18n_attr("position")}/#{self.name}"
    self.machine_field.name = "#{record_i18n_attr("machine")}/#{self.name}"
  end

  def to_label
    "#{self.name}"
  end

  def initialize_dup(other)
    super
    self.ranking_columns = other.ranking_columns.map(&:dup)
    self.ranking_groups = other.ranking_groups.map(&:dup)
    self.ranking_processes = other.ranking_processes.map(&:dup)
    self.form_template = nil
    self.create_form_template
  end
end
