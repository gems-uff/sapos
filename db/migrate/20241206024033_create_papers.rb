# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreatePapers < ActiveRecord::Migration[7.0]
  def change
    create_table :papers do |t|
      t.string :period
      t.text :reference
      t.string :kind
      t.string :doi_issn_event
      t.references :owner, null: false, foreign_key: { to_table: :professors }
      t.text :other_authors
      t.boolean :reason_impact_factor, null: false, default: false
      t.boolean :reason_international_list, null: false, default: false
      t.boolean :reason_citations, null: false, default: false
      t.boolean :reason_national_interest, null: false, default: false
      t.boolean :reason_international_interest, null: false, default: false
      t.boolean :reason_national_representativeness, null: false, default: false
      t.boolean :reason_scientific_contribution, null: false, default: false
      t.boolean :reason_tech_contribution, null: false, default: false
      t.boolean :reason_innovation_contribution, null: false, default: false
      t.boolean :reason_social_contribution, null: false, default: false
      t.text :reason_other
      t.text :reason_justify
      t.string :impact_factor
      t.integer :order
      t.text :other

      t.timestamps
    end
  end
end
