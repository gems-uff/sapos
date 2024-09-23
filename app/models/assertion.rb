# frozen_string_literal: true

class Assertion < ApplicationRecord
  has_paper_trail

  belongs_to :query, inverse_of: :assertions, optional: false

  DERIVATION_DEFS = {
    "data_consulta" => { name: "data_consulta", value_type: "Date" }
  }
  DERIVED_PARAMS = {
    "numero_ultimo_semestre" => "data_consulta",
    "ano_ultimo_semestre" => "data_consulta",
    "numero_semestre_atual" => "data_consulta",
    "ano_semestre_atual" => "data_consulta",
  }

  validates :name, presence: true
  validates :assertion_template, presence: true, on: :update

  def to_label
    "#{self.name}"
  end
end
