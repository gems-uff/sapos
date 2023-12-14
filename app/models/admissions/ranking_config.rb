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

  belongs_to :form_template, optional: true,
    class_name: "Admissions::FormTemplate"
  belongs_to :position_field, optional: true,
    class_name: "Admissions::FormField", foreign_key: "position_field_id"
  belongs_to :machine_field, optional: true,
    class_name: "Admissions::FormField", foreign_key: "machine_field_id"

  validates :name, presence: true
  validates :ranking_columns, length: { minimum: 1 }
  validates :ranking_processes, length: { minimum: 1 }

  before_save :create_form_template

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
    self.position_field.name = "Posição/#{self.name}"
    self.machine_field.name = "Seletor/#{self.name}"
  end

  def to_label
    "#{self.name}"
  end
end
